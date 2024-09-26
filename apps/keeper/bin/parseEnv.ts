import { z, ZodError, ZodIntersection, ZodTypeAny } from "zod";

const commonSchema = z.object({
  SERVER_HOST: z.string().default("0.0.0.0"),
  SERVER_PORT: z.coerce.number().positive().default(8080),
  HASURA_ADMIN_SECRET: z.string(),
  TARGET_TOKEN: z.string(),
  GRAPHQL_URL: z.string().default("https://tub-graphql.primodium.ai/v1/graphql"),
  PRIVATE_KEY: z
    .string()
    .default(
      "9344dc8d6fbc1a788e75195e0e6e4c5910b200633baf9818d956c80580e82303bd7e14bda125a12268d3862688f2acf77d1a2d0e258540d041bf9722cabd4a14",
    ),
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
