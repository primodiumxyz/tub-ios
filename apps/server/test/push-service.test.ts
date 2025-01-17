import { MEMECOIN_MAINNET_PUBLIC_KEY } from "@/constants/tokens";
import { Config } from "@/services/ConfigService";
import { GqlClient, createClient as createGqlClient } from "@tub/gql";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { PushService } from "../src/services/ApplePushService";
import { env } from "@bin/tub-server";

describe("PushService", () => {
  let pushService: PushService;
  let gqlClient: GqlClient["db"];
  const tokenMint = MEMECOIN_MAINNET_PUBLIC_KEY.toBase58();

  beforeEach(async () => {
    gqlClient = (
      await createGqlClient({
        url: env.GRAPHQL_URL,
        hasuraAdminSecret: env.HASURA_ADMIN_SECRET,
      })
    ).db;

    pushService = new PushService({
      gqlClient,
      config: {
        PUSH_REGISTRY_TIMEOUT_MS: 6 * 60 * 60 * 1000, // six hours
        PUSH_CLEANUP_INTERVAL_MS: 60000,
        PUSH_SEND_INTERVAL_MS: 1000,
      } as Config,
    });
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  /* ------------------------- Private Method Tests ------------------------- */

  describe("cleanupRegistry", () => {
    it("should remove expired items and clean subscriptions", async () => {
      // @ts-expect-error accessing private
      pushService.pushRegistry.set("user1", {
        tokenMint,
        initialPriceUsd: "1.0",
        deviceToken: "token1",
        timestamp: Date.now() - 7 * 60 * 60 * 1000, // 7 hours ago
      });

      // @ts-expect-error accessing private
      pushService.subscriptions.set(tokenMint, {
        subscription: { unsubscribe: vi.fn() },
        subCount: 1,
      });

      // @ts-expect-error accessing private
      await pushService.cleanupRegistry();

      // @ts-expect-error accessing private
      expect(pushService.pushRegistry.size).toBe(0);
      // @ts-expect-error accessing private
      expect(pushService.subscriptions.size).toBe(0);
    });
  });

  describe("beginTokenSubscription", () => {
    it("should increment subCount for existing subscription", () => {
      const mockUnsubscribe = vi.fn();

      // @ts-expect-error accessing private
      pushService.subscriptions.set(tokenMint, {
        subscription: { unsubscribe: mockUnsubscribe },
        subCount: 1,
      });

      // @ts-expect-error accessing private
      pushService.beginTokenSubscription(tokenMint);

      // @ts-expect-error accessing private
      expect(pushService.subscriptions.get(tokenMint)?.subCount).toBe(2);
      expect(mockUnsubscribe).not.toHaveBeenCalled();
    });

    it("should create new subscription for new token", () => {
      // @ts-expect-error accessing private
      pushService.beginTokenSubscription(tokenMint);

      // @ts-expect-error accessing private
      expect(pushService.subscriptions.has(tokenMint)).toBe(true);
      // @ts-expect-error accessing private
      expect(pushService.subscriptions.get(tokenMint)?.subCount).toBe(1);
    });
  });

  describe("cleanSubscription", () => {
    it("should decrement subCount and cleanup when zero", async () => {
      const mockUnsubscribe = vi.fn();

      // @ts-expect-error accessing private
      pushService.subscriptions.set(tokenMint, {
        subscription: { unsubscribe: mockUnsubscribe },
        subCount: 1,
      });

      // @ts-expect-error accessing private
      await pushService.cleanSubscription(tokenMint);

      // @ts-expect-error accessing private
      expect(pushService.subscriptions.has(tokenMint)).toBe(false);
      expect(mockUnsubscribe).toHaveBeenCalled();
    });
  });

  /* ------------------------- Public Method Tests ------------------------- */

  describe("startLiveActivity", () => {
    it("should register new activity and start subscription", async () => {
      const userId = "user1";
      const input = {
        tokenMint,
        tokenPriceUsd: "1.0",
        deviceToken: "token1",
        pushToken: "pushToken1",
      };

      await pushService.startLiveActivity(userId, input);

      // @ts-expect-error accessing private
      expect(pushService.pushRegistry.has(userId)).toBe(true);
      // @ts-expect-error accessing private
      expect(pushService.subscriptions.has(input.tokenMint)).toBe(true);
    });

    it("should not duplicate existing activity", async () => {
      const userId = "user1";
      const input = {
        tokenMint,
        tokenPriceUsd: "1.0",
        deviceToken: "token1",
        pushToken: "pushToken1",
      };

      await pushService.startLiveActivity(userId, input);
      await pushService.startLiveActivity(userId, input);

      // @ts-expect-error accessing private
      expect(pushService.pushRegistry.size).toBe(1);
      // @ts-expect-error accessing private
      expect(pushService.subscriptions.get(input.tokenMint)?.subCount).toBe(1);
    });
  });

  describe("stopLiveActivity", () => {
    it("should remove activity and clean subscription", async () => {
      const userId = "user1";

      // @ts-expect-error accessing private
      pushService.pushRegistry.set(userId, {
        tokenMint,
        initialPriceUsd: "1.0",
        deviceToken: "token1",
        pushToken: "pushToken1",
        timestamp: Date.now(),
      });

      // @ts-expect-error accessing private
      pushService.subscriptions.set(tokenMint, {
        subscription: { unsubscribe: vi.fn() },
        subCount: 1,
      });

      await pushService.stopLiveActivity(userId);

      // @ts-expect-error accessing private
      expect(pushService.pushRegistry.has(userId)).toBe(false);
      // @ts-expect-error accessing private
      expect(pushService.subscriptions.has(tokenMint)).toBe(false);
    });
  });

  it("should maintain activity for 10 seconds then clean up properly", async () => {
    const userId = "user1";
    const input = {
      tokenMint,
      tokenPriceUsd: "1.0",
      deviceToken: "token1",
      pushToken: "pushToken1",
    };

    await pushService.startLiveActivity(userId, input);

    // @ts-expect-error accessing private
    expect(pushService.pushRegistry.has(userId)).toBe(true);
    // @ts-expect-error accessing private
    expect(pushService.subscriptions.has(input.tokenMint)).toBe(true);

    vi.useRealTimers();
    await new Promise((resolve) => setTimeout(resolve, 3000));

    await pushService.stopLiveActivity(userId);

    // @ts-expect-error accessing private
    expect(pushService.pushRegistry.has(userId)).toBe(false);
    // @ts-expect-error accessing private
    expect(pushService.subscriptions.has(input.tokenMint)).toBe(false);
  }, 4000);
});
