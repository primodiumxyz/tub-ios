import { execSync } from "child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "fs";
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import pg from "pg";
import yaml from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const LOCAL_URL = "postgres://tsdbadmin:password@localhost:5433/indexer";
const LOCAL_PASSWORD = "password";

interface Config {
  endpoint?: string;
  adminSecret?: string;
}

async function getClient(config?: Config) {
  const connectionString = config?.endpoint ?? LOCAL_URL;
  const password = config?.adminSecret ?? LOCAL_PASSWORD;

  return new pg.Client({
    connectionString,
    password,
    ssl: connectionString.includes("cloud.timescale.com") ? { rejectUnauthorized: true } : undefined,
  });
}

async function dropExistingFunction(client: pg.Client, functionName: string) {
  try {
    // Get function parameters
    const { rows } = await client.query(
      `
      SELECT pg_get_function_identity_arguments(oid) as args
      FROM pg_proc 
      WHERE proname = $1 
      AND pronamespace = 'public'::regnamespace
    `,
      [functionName],
    );

    if (rows.length > 0) {
      // Drop the function with its specific signature
      await client.query(`DROP FUNCTION IF EXISTS ${functionName}(${rows[0].args})`);
      console.log(`Dropped existing function: ${functionName}`);
    }
  } catch (error) {
    console.warn(`Warning: Failed to drop function ${functionName}:`, error);
  }
}

async function getTables(client: pg.Client) {
  const { rows } = await client.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
  `);
  return rows.map((row) => row.table_name);
}

async function main() {
  const args = process.argv.slice(2);
  const config: Config = {};

  for (let i = 0; i < args.length; i += 2) {
    if (args[i] === "--endpoint") config.endpoint = args[i + 1];
    if (args[i] === "--admin-secret") config.adminSecret = args[i + 1];
  }

  const client = await getClient(config);
  await client.connect();

  try {
    // Get all SQL files
    const dirs = {
      queries: path.resolve(__dirname, "../queries"),
      mutations: path.resolve(__dirname, "../mutations"),
    };

    const operations = [];

    // First, drop all existing functions
    for (const [type, dir] of Object.entries(dirs)) {
      const files = readdirSync(dir).filter((f) => f.endsWith(".sql"));

      for (const file of files) {
        const sql = readFileSync(path.join(dir, file), "utf-8");
        const functionName = file.replace(".sql", "");
        await dropExistingFunction(client, functionName);

        // Execute the new function definition
        await client.query(sql);
        console.log(`Created function: ${functionName}`);

        operations.push({
          name: functionName,
          type: type === "queries" ? "query" : "mutation",
        });
      }
    }

    // Create metadata directories
    const databasesDir = path.resolve(__dirname, "../../../metadata/databases");
    const timescaleDir = path.resolve(databasesDir, "timescaledb");
    const functionsDir = path.resolve(timescaleDir, "functions");
    const tablesDir = path.resolve(timescaleDir, "tables");
    const graphqlDir = path.resolve(__dirname, "../../graphql");

    mkdirSync(timescaleDir, { recursive: true });
    mkdirSync(functionsDir, { recursive: true });
    mkdirSync(tablesDir, { recursive: true });
    mkdirSync(graphqlDir, { recursive: true });

    // Create/update databases.yaml
    const databasesConfig = `
- name: timescaledb
  kind: postgres
  configuration:
    connection_info:
      database_url:
        from_env: TIMESCALE_DATABASE_URL
  tables: "!include timescaledb/tables.yaml"
  functions: "!include timescaledb/functions.yaml"
`;

    writeFileSync(path.resolve(databasesDir, "databases.yaml"), databasesConfig);

    // Create function files and index
    const functionIncludes = [];
    for (const op of operations) {
      const functionConfig = {
        function: {
          name: op.name,
          schema: "public",
        },
        configuration: {
          exposed_as: op.type,
          arguments: {
            session_argument: null,
          },
        },
      };

      const fileName = `${op.name}.yaml`;
      writeFileSync(path.resolve(functionsDir, fileName), yaml.stringify(functionConfig));
      functionIncludes.push(`- "!include functions/${fileName}"`);
    }

    writeFileSync(path.resolve(timescaleDir, "functions.yaml"), functionIncludes.join("\n"));

    // Create table files and index
    const tables = await getTables(client);
    const tableIncludes = [];

    for (const tableName of tables) {
      const tableConfig = {
        table: {
          name: tableName,
          schema: "public",
        },
        // Add any default permissions here if needed
        select_permissions: [
          {
            role: "public",
            permission: {
              columns: "*",
              filter: {},
              allow_aggregations: true,
            },
          },
        ],
      };

      const fileName = `${tableName}.yaml`;
      writeFileSync(path.resolve(tablesDir, fileName), yaml.stringify(tableConfig));
      tableIncludes.push(`- "!include tables/${fileName}"`);
    }

    writeFileSync(path.resolve(timescaleDir, "tables.yaml"), tableIncludes.join("\n"));

    // Apply metadata changes to Hasura
    try {
      execSync("hasura metadata apply", {
        stdio: "inherit",
        cwd: path.resolve(__dirname, "../../.."),
      });
      console.log("✨ Hasura metadata applied successfully");

      execSync("hasura metadata reload", {
        stdio: "inherit",
        cwd: path.resolve(__dirname, "../../.."),
      });
      console.log("✨ Hasura metadata reloaded successfully");
    } catch (error) {
      console.error("Failed to apply/reload Hasura metadata:", error);
    }

    // Generate operations file
    const operationsContent = `// Generated by sync-operations.ts
export const TimescaleOperations = {
  queries: ${JSON.stringify(
    operations.filter((op) => op.type === "query").map((op) => op.name),
    null,
    2,
  )},
  mutations: ${JSON.stringify(
    operations.filter((op) => op.type === "mutation").map((op) => op.name),
    null,
    2,
  )}
} as const;

export type TimescaleQueries = typeof TimescaleOperations.queries[number];
export type TimescaleMutations = typeof TimescaleOperations.mutations[number];
`;

    const operationsPath = path.resolve(graphqlDir, "timescale-operations.ts");
    writeFileSync(operationsPath, operationsContent);
    console.log("✨ Operations file generated successfully");
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
