import { Codex } from "@codex-data/sdk";

export class CodexService {
  constructor(private codexSdk: Codex) {}

  async requestToken(expiration?: number): Promise<{ token: string; expiry: string }> {
    expiration = expiration ?? 3600 * 1000;
    const res = await this.codexSdk.mutations.createApiTokens({
      input: { expiresIn: expiration },
    });

    const token = res.createApiTokens[0]?.token;
    const expiry = res.createApiTokens[0]?.expiresTimeString;
    if (!token || !expiry) {
      throw new Error("Failed to create Codex API token");
    }
    return { token: `Bearer ${token}`, expiry };
  }
}
