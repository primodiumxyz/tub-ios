import { readdirSync, readFileSync, writeFileSync } from "fs";
import path from "path";
import { parse } from "pg-query-parser";

// 1. Write metadata to Hasura to point to Timescale queries
// 2. Write Timescale SQL to GraphQL queries for correct routing

// Read all SQL files from queries directory
const queriesDir = path.resolve(__dirname, "../src/queries");
const queryFiles = readdirSync(queriesDir).filter((f) => f.endsWith(".sql"));

function extractFunctionInfo(sql: string) {
  const parsed = parse(sql);
  return parsed.queries
    .filter((q) => q.stmt.CreateFunctionStmt)
    .map((q) => {
      const stmt = q.stmt.CreateFunctionStmt;
      return {
        name: stmt.funcname[stmt.funcname.length - 1].String.str,
        args: stmt.parameters.map((p) => ({
          name: p.name,
          type: p.argType.TypeName.names[p.argType.TypeName.names.length - 1].String.str,
        })),
        returnType: stmt.returnType.TypeName.names[stmt.returnType.TypeName.names.length - 1].String.str,
      };
    });
}

// Generate Hasura metadata
const functions = queryFiles.flatMap((file) => {
  const sql = readFileSync(path.resolve(queriesDir, file), "utf8");
  return extractFunctionInfo(sql);
});

// Generate Hasura metadata YAML
const hasuraMetadata = {
  name: "timescaledb",
  kind: "postgres",
  configuration: {
    connection_info: {
      database_url: { from_env: "TIMESCALE_DATABASE_URL" },
    },
  },
  functions: functions.map((f) => ({
    function: {
      name: f.name,
      schema: "public",
    },
  })),
};

// Write Hasura metadata
writeFileSync(
  path.resolve(__dirname, "../../gql/metadata/databases/timescaledb.yaml"),
  JSON.stringify(hasuraMetadata, null, 2),
);

// Generate GraphQL operations
const gqlOperations = functions
  .map(
    (f) => `
export const ${f.name}Query = graphql(\`
  query ${f.name}(${f.args.map((a) => `$${a.name}: ${a.type}!`).join(", ")}) {
    ${f.name}(${f.args.map((a) => `${a.name}: $${a.name}`).join(", ")}) {
      result
    }
  }
\``,
  )
  .join("\n");

writeFileSync(path.resolve(__dirname, "../../gql/src/graphql/timescale-queries.ts"), gqlOperations);
