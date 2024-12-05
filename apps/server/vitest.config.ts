import tsconfigPaths from "vite-tsconfig-paths";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    environment: "node",
    globalSetup: ["./test/setup.ts"],
    setupFiles: ["./test/setup.ts"],
    reporters: ["default", "hanging-process"],
  },
});
