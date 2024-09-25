import { BN } from "@coral-xyz/anchor";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { TubService } from "../src/TubService";

describe("TubService", () => {
  let tubService: TubService;
  let mockCore: any;

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
    tubService = new TubService(mockCore);
  });

  it("should return status 200", () => {
    expect(tubService.getStatus()).toEqual({ status: 200 });
  });

  it("should increment call", () => {
    tubService.incrementCall();
    expect(mockCore.calls.increment).toHaveBeenCalled();
  });

  it("should subscribe and unsubscribe to counter updates", () => {
    const mockCallback = vi.fn();
    tubService.subscribeToCounter(mockCallback);
    expect(mockCore.connection.onAccountChange).toHaveBeenCalled();

    // Simulate counter update
    const mockAccountInfo = { data: "mockData" };
    const mockDecodedCounter = { count: new BN(5) };
    mockCore.programs.counter.coder.accounts.decode.mockReturnValue(mockDecodedCounter);
    mockCore.connection.onAccountChange.mock.calls[0][1](mockAccountInfo);

    expect(mockCallback).toHaveBeenCalledWith(5);

    tubService.unsubscribeFromCounter(mockCallback);
    // You might want to add more assertions here to ensure the unsubscribe logic works
  });
});
