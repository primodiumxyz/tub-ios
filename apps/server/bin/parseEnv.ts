import { z, ZodError, ZodIntersection, ZodTypeAny } from "zod";

const commonSchema = z.object({
  NODE_ENV: z.enum(["local", "dev", "test", "production"]).default("local"),
  SERVER_HOST: z.string().default("0.0.0.0"),
  SERVER_PORT: z.coerce.number().positive().default(8888),
  QUICKNODE_ENDPOINT: z.string().default("https://blue-hardworking-paper.solana-mainnet.quiknode.pro"),
  QUICKNODE_TOKEN: z.string(),
  HASURA_ADMIN_SECRET: z.string().default("password"),
  GRAPHQL_URL: z.string().default("http://localhost:8090/v1/graphql"),
  JWT_SECRET: z.string().default("secret"),
  COINBASE_CDP_API_KEY_NAME: z.string().default(""),
  COINBASE_CDP_API_KEY_PRIVATE_KEY: z.string().default(""),
  CI: z.coerce.boolean().default(false),
  TEST_USER_PRIVATE_KEY: z.string().default("set TEST_USER_PRIVATE_KEY in .env before running server tests"),

  JUPITER_URL: z.string(),
  FEE_PAYER_PRIVATE_KEY: z.string(),
  PRIVY_APP_ID: z.string(),
  PRIVY_APP_SECRET: z.string(),

  REDIS_HOST: z.string().default("localhost"),
  REDIS_PORT: z.coerce.number().default(6379),
  REDIS_PASSWORD: z.string().optional(),
});
export function parseEnv<TSchema extends ZodTypeAny | undefined = undefined>(
  schema?: TSchema,
): z.infer<TSchema extends ZodTypeAny ? ZodIntersection<typeof commonSchema, TSchema> : typeof commonSchema> {
  const envSchema = schema !== undefined ? z.intersection(commonSchema, schema) : commonSchema;
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof ZodError) {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { _errors, ...invalidEnvVars } = error.format();
      console.error(`\nMissing or invalid environment variables:\n\n  ${Object.keys(invalidEnvVars).join("\n  ")}\n`);
      process.exit(1);
    }
    throw error;
  }
}
