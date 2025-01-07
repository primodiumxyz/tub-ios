import Fastify from "fastify";
import { createClient } from "redis";
import { print, parse } from "graphql";

const fastify = Fastify({
  logger: true,
});

const redis = createClient({
  url: "redis://localhost:6379",
});

const HASURA_URL = "http://graphql-engine:8080";
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

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

function parseCacheTime(str: string | undefined): number {
  if (!str) return 30;
  const num = parseInt(str.match(/^(\d+)/)?.[1] || "30");
  const unit = str.match(/[^0-9]+$/)?.[0];

  if (!unit) return num;
  if (unit === "s") return num;
  if (unit === "m") return num * 60;
  if (unit === "h") return num * 3600;
  return 30;
}

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

fastify.post("/v1/graphql", async (request, reply) => {
  const body = request.body as { query: string; variables?: Record<string, unknown> };
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

  const bypassCache = request.headers["x-cache-bypass"] === "1";
  const cacheTime = parseCacheTime(request.headers["x-cache-time"] as string);

  try {
    const query = print(parse(body.query));
    const cacheKey = `gql:${query}:${JSON.stringify(body.variables)}`;

    if (!bypassCache) {
      const cached = await redis.json.get(cacheKey);
      if (cached) {
        reply.header("X-Cache-Status", "HIT");
        return cached;
      }
    }

    const stringifiedBody = JSON.stringify(body);
    const response = await fetchWithRetry(`${HASURA_URL}/v1/graphql`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(stringifiedBody).toString(),
        ...(request.headers as Record<string, string>),
      },
      body: stringifiedBody,
    });

    const data = await response.json();

    if (!bypassCache && response.ok && !data.errors) {
      await redis.json.set(cacheKey, "$", data);
      await redis.expire(cacheKey, cacheTime);
      reply.header("X-Cache-Status", "MISS");
    } else {
      reply.header("X-Cache-Status", "BYPASS");
    }

    reply.status(response.status).send(data);
  } catch (error) {
    request.log.error(error);
    reply.status(500).send({
      errors: [{ message: "Internal server error" }],
    });
  }
});

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
