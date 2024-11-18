#!/usr/bin/env node
import { AppRouter, createAppRouter } from "@/createAppRouter";
import { TubService } from "@/TubService";
import { parseEnv } from "@bin/parseEnv";
import { Codex } from "@codex-data/sdk";
import fastifyWebsocket from "@fastify/websocket";
import { PrivyClient } from "@privy-io/server-auth";
import { fastifyTRPCPlugin } from "@trpc/server/adapters/fastify";
import { applyWSSHandler } from "@trpc/server/adapters/ws";
import { createClient as createGqlClient } from "@tub/gql";
import { config } from "dotenv";
import fastify from "fastify";

config({ path: "../../.env" });

const env = parseEnv();

// @see https://fastify.dev/docs/latest/
export const server = fastify({
  maxParamLength: 5000,
  logger: true,
});

await server.register(import("@fastify/compress"));
await server.register(import("@fastify/cors"));
await server.register(fastifyWebsocket);

// k8s healthchecks
server.get("/healthz", (req, res) => res.code(200).send());
server.get("/readyz", (req, res) => res.code(200).send());
server.get("/", (req, res) => res.code(200).send("hello world"));

// Helper function to extract bearer token
const getBearerToken = (req: any) => {
  const authHeader = req.headers?.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.substring(7);
  }
  return null;
};

export const start = async () => {
  try {
    // const connection = new Connection(clusterApiUrl("devnet"), "confirmed");

    if (!process.env.GRAPHQL_URL && env.NODE_ENV === "production") {
      throw new Error("GRAPHQL_URL is not set");
    }
    const gqlClient = (
      await createGqlClient({
        url: env.NODE_ENV !== "production" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
        hasuraAdminSecret: env.NODE_ENV !== "production" ? "password" : env.HASURA_ADMIN_SECRET,
      })
    ).db;

    const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);
    const codexSdk = new Codex(env.CODEX_API_KEY);

    const tubService = new TubService(gqlClient, privy, codexSdk);

    // @see https://trpc.io/docs/server/adapters/fastify
    server.register(fastifyTRPCPlugin<AppRouter>, {
      prefix: "/trpc",
      useWSS: true,
      trpcOptions: {
        router: createAppRouter(),
        createContext: async (opt) => ({ tubService, jwtToken: getBearerToken(opt.req) }),
      },
    });
    await server.listen({ host: env.SERVER_HOST, port: env.SERVER_PORT });
    console.log(`tub server listening on http://${env.SERVER_HOST}:${env.SERVER_PORT}`);

    // Apply WebSocket handler
    applyWSSHandler({
      wss: server.websocketServer,
      router: createAppRouter(),
      createContext: async (opt) => ({ tubService, jwtToken: getBearerToken(opt.req) }),
    });

    return server;
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};
