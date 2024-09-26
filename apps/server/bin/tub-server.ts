#!/usr/bin/env node
import "dotenv/config";
import { AppRouter, createAppRouter } from "@/createAppRouter";
import { TubService } from "@/TubService";
import { parseEnv } from "@bin/parseEnv";
import { Wallet } from "@coral-xyz/anchor";
import { createCore } from "@core/createCore";
import fastifyWebsocket from "@fastify/websocket";
import { clusterApiUrl, Connection, Keypair } from "@solana/web3.js";
import { fastifyTRPCPlugin } from "@trpc/server/adapters/fastify";
import { applyWSSHandler } from "@trpc/server/adapters/ws";
import fastify from "fastify";
import { createClient as createGqlClient } from "@tub/gql";

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

export const start = async () => {
  try {
    const connection = new Connection(clusterApiUrl("devnet"), "confirmed");

    const wallet = new Wallet(Keypair.fromSecretKey(Buffer.from(env.PRIVATE_KEY, "hex")));
    const core = createCore(wallet, connection);
    if (!process.env.GRAPHQL_URL) {
      throw new Error("GRAPHQL_URL is not set");
    }   
    const gqlClient = createGqlClient({url: process.env.GRAPHQL_URL});
    const tubService = new TubService(core, gqlClient);

    // @see https://trpc.io/docs/server/adapters/fastify
    server.register(fastifyTRPCPlugin<AppRouter>, {
      prefix: "/trpc",
      useWSS: true,
      trpcOptions: {
        router: createAppRouter(),
        createContext: async () => ({ tubService }),
      },
    });
    await server.listen({ host: env.SERVER_HOST, port: env.SERVER_PORT });
    console.log(`tub server listening on http://${env.SERVER_HOST}:${env.SERVER_PORT}`);

    // Apply WebSocket handler
    applyWSSHandler({
      wss: server.websocketServer,
      router: createAppRouter(),
      createContext: async () => ({ tubService }),
    });
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

