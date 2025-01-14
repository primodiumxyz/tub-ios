#!/usr/bin/env node
import fastifyWebsocket from "@fastify/websocket";
import { ConfigurationParameters, createJupiterApiClient } from "@jup-ag/api";
import { PrivyClient } from "@privy-io/server-auth";
import { Connection, Keypair, PublicKey } from "@solana/web3.js";
import { fastifyTRPCPlugin } from "@trpc/server/adapters/fastify";
import { NodeHTTPCreateContextFnOptions } from "@trpc/server/adapters/node-http";
import { applyWSSHandler } from "@trpc/server/adapters/ws";
import { createClient as createGqlClient } from "@tub/gql";
import bs58 from "bs58";
import { config } from "dotenv";
import fastify from "fastify";
import { parseEnv } from "../bin/parseEnv";
import { AppRouter, createAppRouter } from "../src/createAppRouter";
import { JupiterService } from "../src/services/JupiterService";
import { TubService } from "../src/services/TubService";
import { config as configUtils } from "../src/utils/config";

config({ path: "../../.env" });

export const env = parseEnv();

// @see https://fastify.dev/docs/latest/
export const server = fastify({
  maxParamLength: 5000,
  logger: true,
});

export type FeeOptions = {
  amount: number;
  sourceAccount: PublicKey;
  destinationAccount: PublicKey;
};

await server.register(import("@fastify/compress"));
await server.register(import("@fastify/cors"));
await server.register(fastifyWebsocket);

// k8s healthchecks
server.get("/healthz", (_, res) => res.code(200).send());
server.get("/readyz", (_, res) => res.code(200).send());
server.get("/", (_, res) => res.code(200).send("hello world"));

// Helper function to extract bearer token
// @ts-expect-error IncomingMessage is not typed
const getBearerToken = (req: IncomingMessage) => {
  const authHeader = req.headers?.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.substring(7);
  }
  return null;
};

export const start = async () => {
  try {
    const connection = new Connection(`${env.QUICKNODE_ENDPOINT}/${env.QUICKNODE_TOKEN}`, "confirmed");

    // Initialize fee payer keypair from base58 private key
    const feePayerKeypair = Keypair.fromSecretKey(bs58.decode(env.FEE_PAYER_PRIVATE_KEY));

    if (!feePayerKeypair) {
      throw new Error("Fee payer keypair not found");
    }

    if (!(await configUtils()).TRADE_FEE_RECIPIENT) {
      throw new Error("TRADE_FEE_RECIPIENT is not set");
    }

    const jupiterConfig: ConfigurationParameters = {
      basePath: env.JUPITER_URL,
    };

    const jupiterQuoteApi = createJupiterApiClient(jupiterConfig);

    // Initialize JupiterService
    const jupiterService = new JupiterService(connection, jupiterQuoteApi);

    if (!env.GRAPHQL_URL && env.NODE_ENV === "production") {
      throw new Error("GRAPHQL_URL is not set");
    }
    const gqlClient = (
      await createGqlClient({
        url: env.NODE_ENV !== "production" ? "http://localhost:8080/v1/graphql" : env.GRAPHQL_URL,
        hasuraAdminSecret: env.NODE_ENV !== "production" ? "password" : env.HASURA_ADMIN_SECRET,
      })
    ).db;

    const privy = new PrivyClient(env.PRIVY_APP_ID, env.PRIVY_APP_SECRET);

    const tubService = await TubService.create(gqlClient, privy, jupiterService);

    // @see https://trpc.io/docs/server/adapters/fastify
    server.register(fastifyTRPCPlugin<AppRouter>, {
      prefix: "/trpc",
      useWSS: true,
      trpcOptions: {
        router: createAppRouter(),
        createContext: async (opt) => ({
          tubService,
          jwtToken: getBearerToken(opt.req) ?? "",
        }),
      },
    });
    await server.listen({ host: env.SERVER_HOST, port: env.SERVER_PORT });
    console.log(`tub server listening on http://${env.SERVER_HOST}:${env.SERVER_PORT}`);

    // Apply WebSocket handler
    applyWSSHandler({
      wss: server.websocketServer,
      router: createAppRouter(),
      // @ts-expect-error IncomingMessage is not typed
      createContext: async (opt: NodeHTTPCreateContextFnOptions<IncomingMessage, WebSocket>) => ({
        tubService,
        jwtToken: getBearerToken(opt.req) ?? "",
      }),
    });

    return server;
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};
