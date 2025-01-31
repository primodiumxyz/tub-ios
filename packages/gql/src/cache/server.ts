import cors from "@fastify/cors";
import Fastify from "fastify";
import { parse, print } from "graphql";
import { createClient } from "redis";

/* -------------------------------- CONSTANTS ------------------------------- */
// The cache time in seconds
const CACHE_TIME = Number(process.env.CACHE_TIME ?? 30);

// Read the `REDIS_PASSWORD` set in the environment variable to restrict access to the flush endpoint
const REDIS_PASSWORD = process.env.REDIS_PASSWORD ?? "password";

/* -------------------------------- INTERNAL -------------------------------- */
// The internal Hasura URL (which will run in the same container as this server)
const HASURA_URL = "http://graphql-engine:8080";

// Number of retries for the fetchWithRetry function
const MAX_RETRIES = 3;
// 1 second delay between retries
const RETRY_DELAY = 1000;

/* ---------------------------------- SETUP --------------------------------- */
const fastify = Fastify({
  logger: true,
});

// Add explicit CORS configuration if running locally
const dev = process.env.NODE_ENV === "local";
if (dev) {
  await fastify.register(cors, {
    origin: [
      "http://localhost:5173", // Vite dev server
      "http://localhost:8888", // Server
    ],
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-cache-bypass", "x-cache-time", "x-redis-secret"],
    credentials: true,
  });
}

// Create the local connection to Redis
const redis = createClient({
  url: "redis://localhost:8091",
});

/**
 * Fetches a URL with retry logic.
 *
 * @param url - The URL to fetch
 * @param options - The request options
 * @param retries (optional, default: MAX_RETRIES) - The number of retries
 * @returns The response from the URL
 */
async function fetchWithRetry(url: string, options: RequestInit, retries = MAX_RETRIES): Promise<Response> {
  try {
    const response = await fetch(url, options);
    if (!response.ok && retries > 0) {
      fastify.log.warn(`Request failed with status ${response.status}. Retrying... (${retries} attempts left)`);
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY));
      return fetchWithRetry(url, options, retries - 1);
    }
    return response;
  } catch (error) {
    if (retries > 0) {
      fastify.log.warn(`Request failed with error: ${error}. Retrying... (${retries} attempts left)`);
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY));
      return fetchWithRetry(url, options, retries - 1);
    }
    throw error;
  }
}

/**
 * Parses the optional cache time passed in the request headers from a string.
 *
 * @param str - The string to parse
 * @returns The cache time in seconds
 */
function parseCacheTime(str: string | undefined): number {
  if (!str) return CACHE_TIME;
  const num = parseInt(str.match(/^(\d+)/)?.[1] || CACHE_TIME.toString());
  const unit = str.match(/[^0-9]+$/)?.[0];

  if (!unit) return num;
  if (unit === "s") return num;
  if (unit === "m") return num * 60;
  if (unit === "h") return num * 3600;
  return CACHE_TIME;
}

/* ---------------------------------- ENDPOINTS ------------------------------ */
/**
 * Health check endpoint.
 *
 * @example
 *   ```bash
 *   curl http://localhost:8090/healthz
 *   curl http://localhost:8090/healthz?strict=true
 *   # => {"status":"ok"}
 *   # => {"status":"error","message":"Hasura health check failed"}
 *   ```;
 *
 * @param request - The request object
 * @param reply - The reply object
 * @returns The health check response
 */
fastify.get("/healthz", async (request, reply) => {
  const strict = (request.query as Record<string, string>).strict === "true";

  try {
    // Check Redis connection
    await redis.ping();

    if (strict) {
      // Also check Hasura connection
      const response = await fetch(`${HASURA_URL}/healthz`);
      if (!response.ok) {
        throw new Error("Hasura health check failed");
      }
    }

    return reply.status(200).send({ status: "ok" });
  } catch (error) {
    return reply.status(503).send({
      status: "error",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

/**
 * GraphQL endpoint.
 *
 * This will route any mutation directly to Hasura, or run the cache logic if it's a query. Meaning that:
 *
 * - If the query has been cached recently, it will return the cached result
 * - If the cache is stale, it will run the query against Hasura and cache the result
 * - If some `x-cache-bypass` header is set, it will run the query against Hasura and ignore the cache
 * - If some `x-cache-time` header is set, it will use that time to override the default cache time for this specific
 *   query
 *
 * @param request - The request object
 * @param reply - The reply object
 * @returns The GraphQL response
 */
fastify.post("/v1/graphql", async (request, reply) => {
  const body = request.body as { query: string; variables?: Record<string, unknown> };
  const start = performance.now();
  const parsedQuery = parse(body.query);

  // If it's a mutation, bypass cache entirely
  if (parsedQuery.definitions.some((def) => def.kind === "OperationDefinition" && def.operation === "mutation")) {
    const response = await fetchWithRetry(`${HASURA_URL}/v1/graphql`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(request.headers as Record<string, string>),
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    reply.header("X-Cache-Status", "BYPASS");
    return reply.status(response.status).send(data);
  }

  // Read headers
  const bypassCache = request.headers["x-cache-bypass"] === "1";
  const cacheTime = parseCacheTime(request.headers["x-cache-time"] as string);

  try {
    const query = print(parse(body.query));
    const cacheKey = `gql:${query}:${JSON.stringify(body.variables)}`;

    // If the cache is not bypassed, check if the query is cached
    if (!bypassCache) {
      const cached = await redis.json.get(cacheKey);
      const checkTime = performance.now();
      fastify.log.info({
        msg: cached ? "Cache HIT" : "Cache MISS",
        cacheKey,
        checkDuration: checkTime - start,
        cached: !!cached,
      });

      // If the cache is hit, return the cached result
      if (cached) {
        reply.header("X-Cache-Status", "HIT");
        return cached;
      }
    }

    // If the cache is not hit, run the query against Hasura
    const stringifiedBody = JSON.stringify(body);
    const fetchStart = performance.now();
    const response = await fetchWithRetry(`${HASURA_URL}/v1/graphql`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(stringifiedBody).toString(),
        ...(request.headers as Record<string, string>),
      },
      body: stringifiedBody,
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data = (await response.json()) as { [key: string]: any };

    fastify.log.info({
      msg: "Hasura fetch completed",
      duration: performance.now() - fetchStart,
    });

    // If the cache is not bypassed, save the result to the cache
    if (!bypassCache && response.ok && !data.errors) {
      const cacheStart = performance.now();
      await redis.json.set(cacheKey, "$", data);
      await redis.expire(cacheKey, cacheTime);
      fastify.log.info({
        msg: "Cache save completed",
        duration: performance.now() - cacheStart,
      });
      reply.header("X-Cache-Status", "MISS");
    } else {
      fastify.log.info({
        msg: "Cache BYPASS",
        cacheKey,
      });
      reply.header("X-Cache-Status", "BYPASS");
    }

    // Return the response from Hasura
    return reply.status(response.status).send(data);
  } catch (error) {
    request.log.error(error);
    reply.status(500).send({
      errors: [{ message: "Internal server error" }],
    });
  }
});

/**
 * Authenticated flush endpoint to clear the entire cache.
 *
 * @param request - The request object
 * @param reply - The reply object
 * @returns The flush response
 */
fastify.post("/flush", async (request, reply) => {
  const redisSecret = request.headers["x-redis-secret"];
  if (redisSecret !== REDIS_PASSWORD) return reply.status(401).send({ error: "Invalid Redis secret" });

  try {
    fastify.log.info("Starting cache flush");
    await redis.flushAll();

    fastify.log.info("Cache flush completed and verified");
    return reply.status(200).send({ success: true, keysRemaining: 0 });
  } catch (error) {
    fastify.log.error(error);
    return reply.status(500).send({ error: "Failed to flush cache" });
  }
});

/**
 * Start the cache server.
 *
 * @internal
 */
const start = async () => {
  try {
    await redis.connect();
    await fastify.listen({ port: 8090, host: "0.0.0.0" });
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
