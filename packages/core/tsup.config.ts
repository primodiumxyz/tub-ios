import { defineConfig } from "tsup";

export default defineConfig([
  {
    entry: {
      index: "src/index.ts",
    },
    outDir: "dist",
    format: ["esm"],
    dts: true,
    clean: true,
    minify: true,
    tsconfig: "./tsconfig.json",
  },
]);
