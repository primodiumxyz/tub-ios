import { execSync } from "child_process";
import { mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TEMP_DIR = path.resolve(__dirname, "../temp-queries");

function extractFunctionInfo(sql: string) {
  // Match function name, params and return type
  const functionMatch = sql.match(
    /CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?(\w+)\s*\(([\s\S]*?)\)\s+RETURNS\s+(?:SETOF\s+)?([^\s]+)/,
  );
  if (!functionMatch) return null;

  const [_, name, params, returnType] = functionMatch;

  // Parse parameters
  const parameters = params?.split(",").map((param) => {
    const [paramName, paramType] = param.trim().split(/\s+/);
    return { name: paramName, type: paramType };
  });

  return { name, parameters, returnType };
}

async function main() {
  try {
    // Create temp directory
    rmSync(TEMP_DIR, { recursive: true, force: true });
    mkdirSync(TEMP_DIR, { recursive: true });

    // Read all SQL files from queries and mutations
    const dirs = ["queries", "mutations"].map((dir) => path.resolve(__dirname, "..", dir));

    for (const dir of dirs) {
      const files = readdirSync(dir).filter((f) => f.endsWith(".sql"));

      for (const file of files) {
        const sql = readFileSync(path.join(dir, file), "utf-8");
        const functionInfo = extractFunctionInfo(sql);

        if (functionInfo) {
          const { name, parameters } = functionInfo;

          // Generate query that calls the function with parameter types
          const queryContent = `/*
  @name ${name}
${parameters?.map((p) => `  @param ${p.name} -> ${p.type === "JSONB" ? "(...)" : p.type}`).join("\n")}
*/
select * from ${name}(${parameters?.map((p) => `:${p.name}`).join(", ")});`;

          writeFileSync(path.join(TEMP_DIR, `${name}.sql`), queryContent);
        }
      }
    }

    // Read the existing config file
    const configPath = path.resolve(__dirname, "../../../pgtyped-config.json");
    const existingConfig = JSON.parse(readFileSync(configPath, "utf-8"));

    // Create temporary config
    const tempConfig = {
      ...existingConfig,
      transforms: [
        {
          mode: "sql",
          include: "src/timescale/temp-queries/**/*.sql",
          emitTemplate: "src/timescale/types/{{name}}.generated.ts",
        },
      ],
    };

    writeFileSync(path.join(TEMP_DIR, "pgtyped-config.json"), JSON.stringify(tempConfig, null, 2));

    execSync("pgtyped -c src/timescale/temp-queries/pgtyped-config.json", {
      stdio: "inherit",
      cwd: path.resolve(__dirname, "../../.."),
    });
  } finally {
    // Cleanup
    rmSync(TEMP_DIR, { recursive: true, force: true });
  }
}

main().catch(console.error);
