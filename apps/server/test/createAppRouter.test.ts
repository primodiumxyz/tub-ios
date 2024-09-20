import { beforeEach, describe, expect, it, Mocked, vi } from "vitest";
import { createAppRouter } from "../src/createAppRouter";
import type { AppRouter } from "../src/createAppRouter";
import { TubService } from "../src/TubService";

describe("createAppRouter", () => {
  let appRouter: AppRouter;
  const mockTubService = {
    getStatus: vi.fn().mockReturnValue({ status: 200 }),
    incrementCall: vi.fn(),
    subscribeToCounter: vi.fn(),
    unsubscribeFromCounter: vi.fn(),
  } as unknown as Mocked<TubService>;

  beforeEach(() => {
    appRouter = createAppRouter();
  });

  it("should have getStatus procedure", async () => {
    const caller = appRouter.createCaller({ tubService: mockTubService });
    const result = await caller.getStatus();
    expect(result).toEqual({ status: 200 });
  });

  it("should have incrementCall procedure", async () => {
    const caller = appRouter.createCaller({ tubService: mockTubService });
    await caller.incrementCall();
    expect(mockTubService.incrementCall).toHaveBeenCalled();
  });

  it("should have onCounterUpdate subscription", () => {
    const procedure = appRouter._def.procedures["onCounterUpdate"];
    expect(procedure).toBeDefined();
  });
});
