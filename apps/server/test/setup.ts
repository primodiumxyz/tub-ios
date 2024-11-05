import { afterAll, afterEach, beforeAll } from "vitest";
import { server, start } from "../bin/tub-server";

beforeAll(async () => {
  await start();
});

afterAll(async () => {
  server.close();
});

afterEach(() => {
  // Clean up after each test
});
