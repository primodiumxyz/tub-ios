import { TubService } from "../../src/services/TubService";
import { GqlClient } from "@tub/gql";
import { Codex } from "@codex-data/sdk";
import { JupiterService } from "../../src/services/JupiterService";

export class MockTubService extends TubService {
  private testWalletAddress: string;

  constructor(gqlClient: GqlClient["db"], codexSdk: Codex, jupiter: JupiterService, testWalletAddress: string) {
    // Pass empty objects for Privy since we won't use it
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    super(gqlClient, {} as any, codexSdk, jupiter);
    this.testWalletAddress = testWalletAddress;
  }

  // Override the private methods that use Privy
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  protected override async verifyJWT(_token: string): Promise<string> {
    return "test_user_id";
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  protected override async getUserWallet(_userId: string): Promise<string> {
    return this.testWalletAddress;
  }
}
