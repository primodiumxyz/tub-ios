#!/usr/bin/env node

import "dotenv/config";

import { fastifyTRPCPlugin } from "@trpc/server/adapters/fastify";
import fastify from "fastify";

import { parseEnv } from "@bin/parseEnv";
import { AppRouter, createAppRouter } from "@/createAppRouter";
import { TubService } from "@/TubService";

const env = parseEnv();

// @see https://fastify.dev/docs/latest/
const server = fastify({
  maxParamLength: 5000,
  logger: true,
});

await server.register(import("@fastify/compress"));
await server.register(import("@fastify/cors"));

// k8s healthchecks
server.get("/healthz", (req, res) => res.code(200).send());
server.get("/readyz", (req, res) => res.code(200).send());

const tubService = new TubService();

// server.addHook("preHandler", (req, reply, done) => {
//   if (req.headers.authorization !== `Bearer ${env.KEEPER_BEARER_TOKEN}`) {
//     reply.code(401).send({ error: "Unauthorized" });
//   } else {
//     done();
//   }
// });

// @see https://trpc.io/docs/server/adapters/fastify
server.register(fastifyTRPCPlugin<AppRouter>, {
  prefix: "/trpc",
  trpcOptions: {
    router: createAppRouter(),
    createContext: async () => ({ tubService }),
  },
});

await server.listen({ host: env.SERVER_HOST, port: env.SERVER_PORT });
console.log(`tub server listening on http://${env.SERVER_HOST}:${env.SERVER_PORT}`);
