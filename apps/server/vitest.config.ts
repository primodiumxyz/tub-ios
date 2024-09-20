import { defineConfig } from 'vitest/config';

export default defineConfig({
//   plugins: [tsconfigPaths()],
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./test/setup.ts'],
  },
});