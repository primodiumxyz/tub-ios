import { readdirSync, readFileSync, writeFileSync } from "fs";
import path from "path";
import { Client } from "pg";

const LOCAL_URL = "postgres://tsdbadmin:password@localhost:5433/indexer";
const LOCAL_PASSWORD = "password";

interface Config {
  endpoint?: string;
  adminSecret?: string;
}

async function getClient(config?: Config) {
  const connectionString = config?.endpoint ?? LOCAL_URL;
  const password = config?.adminSecret ?? LOCAL_PASSWORD;

  return new Client({
    connectionString,
    password,
    ssl: connectionString.includes("cloud.timescale.com") ? { rejectUnauthorized: true } : undefined,
  });
}

async function main() {
  const args = process.argv.slice(2);
  const isRemote = args.includes("--remote");
  const config: Config = {};

  for (let i = 0; i < args.length; i += 2) {
    if (args[i] === "--endpoint") config.endpoint = args[i + 1];
    if (args[i] === "--admin-secret") config.adminSecret = args[i + 1];
  }

  const client = await getClient(config);
  await client.connect();

  try {
    // 1. Apply SQL functions to TimescaleDB
    const dirs = ["queries", "mutations"];
    const operations: { name: string; type: "query" | "mutation" }[] = [];

    for (const dir of dirs) {
      const operationsDir = path.resolve(__dirname, `../${dir}`);
      const files = readdirSync(operationsDir).filter((f) => f.endsWith(".sql"));

      for (const file of files) {
        const sql = readFileSync(path.resolve(operationsDir, file), "utf8");
        await client.query(sql);
        operations.push({
          name: file.replace(".sql", ""),
          type: dir === "queries" ? "query" : "mutation",
        });
      }
    }

    // 2. Generate Hasura metadata
    const hasuraMetadata = {
      name: "timescaledb",
      kind: "postgres",
      configuration: {
        connection_info: {
          database_url: isRemote ? { from_env: "TIMESCALE_URL" } : LOCAL_URL,
        },
      },
      functions: operations.map((op) => ({
        function: {
          name: op.name,
          schema: "public",
        },
      })),
    };

    writeFileSync(
      path.resolve(__dirname, "../../metadata/databases/timescaledb.yaml"),
      JSON.stringify(hasuraMetadata, null, 2),
    );

    // 3. Generate GraphQL operations
    const gqlOperations = operations
      .map((op) => {
        const { name, type } = op;
        const camelCaseName = name.replace(/_/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());

        if (type === "query") {
          return `
export const ${camelCaseName}Query = graphql(\`
  query ${camelCaseName}($token_mint: String!, $interval_minutes: Int!) {
    ${name}(args: {token_mint: $token_mint, interval_minutes: $interval_minutes}) {
      bucket
      token_mint
      token_metadata
      avg_price
      total_volume
      trade_count
    }
  }
\`);`;
        } else {
          return `
export const ${camelCaseName}Mutation = graphql(\`
  mutation ${camelCaseName}($trades: jsonb!) {
    ${name}(args: {trades: $trades}) {
      id
      created_at
      token_mint
      token_price_usd
      volume_usd
      token_metadata
    }
  }
\`);`;
        }
      })
      .join("\n");

    writeFileSync(path.resolve(__dirname, "../../src/graphql/timescale-operations.ts"), gqlOperations);
  } finally {
    await client.end();
  }
}

main().catch(console.error);
