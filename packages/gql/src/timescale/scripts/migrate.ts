import { readdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
import pg from "pg";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const LOCAL_URL = "postgres://tsdbadmin:password@localhost:5433/indexer";
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

  return new pg.Client({
    connectionString,
    password,
    ssl: connectionString.includes("cloud.timescale.com") ? { rejectUnauthorized: true } : undefined,
  });
}

async function ensureMigrationsTable(client: pg.Client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS api.schema_migrations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

async function getAppliedMigrations(client: pg.Client): Promise<Migration[]> {
  const { rows } = await client.query<Migration>("SELECT id, name, applied_at FROM api.schema_migrations ORDER BY id");
  return rows;
}

async function applyMigration(client: pg.Client, name: string, sql: string) {
  await client.query("BEGIN");
  try {
    await client.query(sql);
    await client.query("INSERT INTO api.schema_migrations (name) VALUES ($1)", [name]);
    await client.query("COMMIT");
    console.log(`✅ Applied migration: ${name}`);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(`❌ Failed to apply migration ${name}:`, error);
    throw error;
  }
}

async function revertMigration(client: pg.Client, name: string, sql: string) {
  await client.query("BEGIN");
  try {
    await client.query(sql);
    await client.query("DELETE FROM api.schema_migrations WHERE name = $1", [name]);
    await client.query("COMMIT");
    console.log(`✅ Reverted migration: ${name}`);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(`❌ Failed to revert migration ${name}:`, error);
    throw error;
  }
}

function getTimestamp(): string {
  const now = new Date();
  return now.toISOString().replace(/[-:]/g, "").split(".")[0]?.replace("T", "") ?? "";
}

async function createMigration(name: string) {
  const timestamp = getTimestamp();
  const filename = `${timestamp}_${name}.sql`;
  const template = `-- _UP_ (do not remove this comment)
-- Add your migration SQL here

-- _DOWN_ (do not remove this comment)
-- Add your SQL here to revert the migration
`;

  const migrationsDir = resolve(__dirname, "../migrations");
  writeFileSync(join(migrationsDir, filename), template);
  console.log(`✨ Created migration: ${filename}`);
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || "up";
  const config: Config = {};

  for (let i = 1; i < args.length; i += 2) {
    if (args[i] === "--endpoint") config.endpoint = args[i + 1];
    if (args[i] === "--admin-secret") config.adminSecret = args[i + 1];
  }

  if (command === "create" && args[1]) {
    await createMigration(args[1]);
    return;
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

    const migrationsDir = resolve(__dirname, "../migrations");
    const files = readdirSync(migrationsDir)
      .filter((f) => f.endsWith(".sql"))
      .sort((a, b) => {
        const timestampA = a.split("_")[0];
        const timestampB = b.split("_")[0];
        return timestampA?.localeCompare(timestampB ?? "") ?? 0;
      });

    if (command === "up") {
      const appliedMigrations = await getAppliedMigrations(client);
      const appliedNames = new Set(appliedMigrations.map((m) => m.name));

      for (const file of files) {
        if (!appliedNames.has(file)) {
          const sql = readFileSync(join(migrationsDir, file), "utf8").split("-- _DOWN_")[0];
          if (!sql) throw new Error(`No up migration found in ${file}`);
          await applyMigration(client, file, sql);
        }
      }
      console.log("✨ All migrations applied successfully");
    }

    if (command === "down") {
      const appliedMigrations = await getAppliedMigrations(client);
      if (appliedMigrations.length === 0) {
        console.log("No migrations to revert");
        return;
      }

      const lastMigration = appliedMigrations[appliedMigrations.length - 1];
      if (!lastMigration) throw new Error("No migrations to revert");

      const sql = readFileSync(join(migrationsDir, lastMigration.name), "utf8");
      const downSql = sql.split("-- _DOWN_")[1];

      if (!downSql) {
        throw new Error(`No down migration found in ${lastMigration.name}`);
      }

      await revertMigration(client, lastMigration.name, downSql);
      console.log("✨ Last migration reverted successfully");
    }
  } finally {
    await client.end();
  }
}

main().catch(console.error);
