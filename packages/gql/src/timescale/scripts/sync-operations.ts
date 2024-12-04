import { execSync } from "child_process";
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "fs";
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

async function executeSqlFiles(client: pg.Client, directory: string) {
  const files = readdirSync(directory);

  for (const file of files) {
    if (file.endsWith(".sql")) {
      const filePath = path.join(directory, file);
      const sql = readFileSync(filePath, "utf-8");

      try {
        console.log(`Executing SQL file: ${file}`);
        await client.query(sql);
        console.log(`Successfully executed: ${file}`);
      } catch (error) {
        console.error(`Error executing ${file}:`, error);
      }
    }
  }
}

async function getTables(client: pg.Client) {
  const { rows } = await client.query(`
    SELECT table_name, table_schema
    FROM information_schema.tables 
    WHERE (table_schema = 'api' OR table_name = 'schema_migrations')
    AND table_type = 'BASE TABLE'
  `);

  return rows.map((row) => ({ name: row.table_name, schema: row.table_schema }));
}

async function getCustomTypes(client: pg.Client) {
  const { rows } = await client.query(`
    SELECT t.typname as name, n.nspname as schema
    FROM pg_type t
    JOIN pg_namespace n ON t.typnamespace = n.oid
    WHERE (n.nspname = 'public' OR n.nspname = 'api')
    AND t.typtype = 'c'
  `);

  return rows.map((row) => ({ name: row.name, schema: row.schema }));
}

async function getFunctions(client: pg.Client) {
  const { rows } = await client.query(`
    SELECT 
      p.proname as name,
      n.nspname as schema,
      pg_get_function_result(p.oid) as return_type,
      CASE 
        WHEN p.provolatile = 'i' THEN 'IMMUTABLE'
        WHEN p.provolatile = 's' THEN 'STABLE'
        ELSE 'VOLATILE'
      END as volatility
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'api'
    AND p.prokind = 'f'
  `);

  return rows.map((row) => ({
    name: row.name,
    type: row.return_type.toLowerCase().includes("void") ? "mutation" : "query",
    volatility: row.volatility,
    schema: row.schema,
  }));
}

async function main() {
  const args = process.argv.slice(2);
  const config: Config = {};
  let applyMetadata = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--endpoint") {
      config.endpoint = args[i + 1];
      i++; // Skip next argument
    } else if (args[i] === "--admin-secret") {
      config.adminSecret = args[i + 1];
      i++; // Skip next argument
    } else if (args[i] === "--apply-metadata") {
      applyMetadata = true;
    }
  }

  const client = await getClient(config);
  await client.connect();

  try {
    // Execute SQL files in mutations and queries directories
    const mutationsDir = path.resolve(__dirname, "../../timescale/mutations");
    const queriesDir = path.resolve(__dirname, "../../timescale/queries");

    await executeSqlFiles(client, mutationsDir);
    await executeSqlFiles(client, queriesDir);

    // Create metadata directories
    const databasesDir = path.resolve(__dirname, "../../../metadata/databases");
    const timescaleDir = path.resolve(databasesDir, "timescaledb");
    const functionsDir = path.resolve(timescaleDir, "functions");
    const tablesDir = path.resolve(timescaleDir, "tables");
    const typesDir = path.resolve(timescaleDir, "types");
    const graphqlDir = path.resolve(__dirname, "../../graphql");

    mkdirSync(timescaleDir, { recursive: true });
    mkdirSync(functionsDir, { recursive: true });
    mkdirSync(tablesDir, { recursive: true });
    mkdirSync(typesDir, { recursive: true });
    mkdirSync(graphqlDir, { recursive: true });

    // Create function files and index
    const operations = await getFunctions(client);
    const functionIncludes = [];

    for (const op of operations) {
      const functionConfig = {
        function: {
          name: op.name,
          schema: op.schema,
        },
        configuration: {
          exposed_as: op.type,
          arguments: {
            session_argument: null,
          },
        },
      };

      const fileName = `${op.schema}_${op.name}.yaml`;
      writeFileSync(path.resolve(functionsDir, fileName), yaml.stringify(functionConfig));
      functionIncludes.push(`- "!include ${fileName}"`);
    }

    writeFileSync(path.resolve(functionsDir, "functions.yaml"), functionIncludes.sort().join("\n"));

    // Create table files and index
    const tables = await getTables(client);
    const tableIncludes = [];

    for (const table of tables) {
      const tableConfig = {
        table: {
          name: table.name,
          schema: table.schema,
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

      const fileName = `${table.schema}_${table.name}.yaml`;
      writeFileSync(path.resolve(tablesDir, fileName), yaml.stringify(tableConfig));
      tableIncludes.push(`- "!include ${fileName}"`);
    }

    writeFileSync(path.resolve(tablesDir, "tables.yaml"), tableIncludes.sort().join("\n"));

    // Create types files and index
    const types = await getCustomTypes(client);
    const typeIncludes = [];

    for (const type of types) {
      const typeConfig = {
        type: {
          name: type.name,
          schema: type.schema,
        },
      };

      const fileName = `${type.schema}_${type.name}.yaml`;
      writeFileSync(path.resolve(typesDir, fileName), yaml.stringify(typeConfig));
      typeIncludes.push(`- "!include ${fileName}"`);
    }

    writeFileSync(path.resolve(typesDir, "types.yaml"), typeIncludes.sort().join("\n"));

    // Apply metadata changes to Hasura only if flag is provided
    if (applyMetadata) {
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
    }

    // Generate operations file
    const operationsContent = `// Generated by sync-operations.ts
export const TimescaleOperations = {
  queries: ${JSON.stringify(
    operations
      .filter((op) => op.type === "query")
      .map((op) => op.name)
      .sort(),
    null,
    2,
  )},
  mutations: ${JSON.stringify(
    operations
      .filter((op) => op.type === "mutation")
      .map((op) => op.name)
      .sort(),
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
