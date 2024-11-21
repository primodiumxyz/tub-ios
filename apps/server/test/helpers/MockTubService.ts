import { TubService } from "../../src/TubService";
import { GqlClient } from "@tub/gql";
import { Codex } from "@codex-data/sdk";
import { OctaneService } from "../../src/OctaneService";
import { PublicKey } from "@solana/web3.js";

export class MockTubService extends TubService {
  private testWalletAddress: string;

  constructor(
    gqlClient: GqlClient["db"],
    codexSdk: Codex,
    octane: OctaneService,
    testWalletAddress: string
  ) {
    // Pass empty objects for Privy since we won't use it
    super(gqlClient, {} as any, codexSdk, octane);
    this.testWalletAddress = testWalletAddress;
  }

  // Override the private methods that use Privy
  protected override async verifyJWT(_token: string): Promise<string> {
    return "test_user_id";
  }

  protected override async getUserWallet(_userId: string): Promise<string> {
    return this.testWalletAddress;
  }
} 