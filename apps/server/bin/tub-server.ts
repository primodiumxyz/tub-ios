#!/usr/bin/env node

import "dotenv/config";

import { fastifyTRPCPlugin } from "@trpc/server/adapters/fastify";
import { applyWSSHandler } from "@trpc/server/adapters/ws";
import fastify from "fastify";
import fastifyWebsocket from "@fastify/websocket";

import { parseEnv } from "@bin/parseEnv";
import { AppRouter, createAppRouter } from "@/createAppRouter";
import { TubService } from "@/TubService";
import { createCore } from "@core/createCore";
import { clusterApiUrl, Connection, Keypair } from "@solana/web3.js";
import { Wallet } from "@coral-xyz/anchor";

const env = parseEnv();

// @see https://fastify.dev/docs/latest/
const server = fastify({
  maxParamLength: 5000,
  logger: true,
});

await server.register(import("@fastify/compress"));
await server.register(import("@fastify/cors"));
await server.register(fastifyWebsocket);

// k8s healthchecks
server.get("/healthz", (req, res) => res.code(200).send());
server.get("/readyz", (req, res) => res.code(200).send());

const start = async () => {
  try {
    const connection = new Connection(clusterApiUrl("devnet"), "confirmed");
    const wallet = new Wallet(Keypair.fromSecretKey(Buffer.from(env.PRIVATE_KEY, "hex")));
    const core = createCore(wallet, connection);
    const tubService = new TubService(core);

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

start();
