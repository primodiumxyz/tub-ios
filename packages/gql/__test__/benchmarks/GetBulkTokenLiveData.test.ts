import { beforeAll, describe, it } from "vitest";
import { BenchmarkMockEnvironment, getGlobalEnv } from "./setup";

describe("GetBulkTokenLiveData benchmarks", () => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  let env: BenchmarkMockEnvironment;

  beforeAll(async () => {
    env = await getGlobalEnv();
  });

  it("...", async () => {
    // ...
  });
});
