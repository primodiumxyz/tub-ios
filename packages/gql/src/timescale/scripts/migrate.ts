import { readdirSync, readFileSync } from "fs";
import path from "path";
import { Client } from "pg";

const LOCAL_URL = "postgres://indexer_user:password@localhost:5433/indexer";
const LOCAL_PASSWORD = "password";

interface Config {
  endpoint?: string;
  adminSecret?: string;
}

interface Migration {
  id: number;
  name: string;
  applied_at: Date;
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

async function ensureMigrationsTable(client: Client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

async function getAppliedMigrations(client: Client): Promise<Migration[]> {
  const { rows } = await client.query<Migration>("SELECT id, name, applied_at FROM schema_migrations ORDER BY id");
  return rows;
}

async function applyMigration(client: Client, name: string, sql: string) {
  await client.query("BEGIN");
  try {
    await client.query(sql);
    await client.query("INSERT INTO schema_migrations (name) VALUES ($1)", [name]);
    await client.query("COMMIT");
    console.log(`✅ Applied migration: ${name}`);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(`❌ Failed to apply migration ${name}:`, error);
    throw error;
  }
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || "up";
  const config: Config = {};

  for (let i = 1; i < args.length; i += 2) {
    if (args[i] === "--endpoint") config.endpoint = args[i + 1];
    if (args[i] === "--admin-secret") config.adminSecret = args[i + 1];
  }

  const client = await getClient(config);
  await client.connect();

  try {
    await ensureMigrationsTable(client);

    if (command === "status") {
      const migrations = await getAppliedMigrations(client);
      console.log("\nApplied migrations:");
      console.table(migrations);
      return;
    }

    if (command === "up") {
      const appliedMigrations = await getAppliedMigrations(client);
      const appliedNames = new Set(appliedMigrations.map((m) => m.name));

      const migrationsDir = path.resolve(__dirname, "../migrations");
      const files = readdirSync(migrationsDir)
        .filter((f) => f.endsWith(".sql"))
        .sort();

      for (const file of files) {
        if (!appliedNames.has(file)) {
          const sql = readFileSync(path.join(migrationsDir, file), "utf8");
          await applyMigration(client, file, sql);
        }
      }

      console.log("✨ All migrations applied successfully");
    }
  } finally {
    await client.end();
  }
}

main().catch(console.error);
