import { BN } from "@coral-xyz/anchor";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { TubService } from "../src/TubService";

describe("TubService", () => {
  let tubService: TubService;
  let mockCore: any;
  let mockGqlClient: any;

  beforeEach(() => {
    mockCore = {
      calls: {
        increment: vi.fn(),
      },
      programs: {
        counter: {
          coder: {
            accounts: {
              decode: vi.fn(),
            },
          },
        },
      },
      connection: {
        onAccountChange: vi.fn(),
      },
      pdas: {
        counter: "mockCounterPDA",
      },
    };
    mockGqlClient = {
      db: {
        RegisterNewUserMutation: vi.fn(),
      },
    };
    tubService = new TubService(mockCore, mockGqlClient);
  });

  it("should return a URL starting with the Coinbase onramp URL", async () => {
    const testAddress = "2KNF35JnG97K3oeeEY8BJv4SMfqMQhrZASbD58QQP8f7";
    const expectedUrlStart = "https://pay.coinbase.com/landing\\?sessionToken=";

    // Await the result since getCoinbaseSolanaOnrampUrl is async
    const result = await tubService.getCoinbaseSolanaOnrampUrl(testAddress);

    expect(result.token).toHaveLength(48);
    expect(result.url).toMatch(new RegExp(`^${expectedUrlStart}`));
  });
});
