import { Connection, PublicKey } from "@solana/web3.js";
import { DefaultApi, Configuration } from "@jup-ag/api";
import { OctaneService } from "../src/OctaneService";
import { Keypair } from "@solana/web3.js";
import { caching } from "cache-manager";
import { describe, it, expect, beforeAll } from 'vitest';
import { AxiosError } from 'axios';

const createTestKeypair = () => Keypair.generate();

describe("Jupiter Quote Integration Test", () => {
  let octaneService: OctaneService;
  let jupiterQuoteApi: DefaultApi;
  
  beforeAll(async () => {
    try {
      // Setup connection to Solana mainnet
      const connection = new Connection(process.env.QUICKNODE_MAINNET_URL ?? 'https://api.mainnet-beta.solana.com');
      
      // Setup Jupiter API client
      jupiterQuoteApi = new DefaultApi(
        new Configuration({
          basePath: process.env.JUPITER_URL
        })
      );

    const cache = await caching({
      store: 'memory',
      max: 100,
      ttl: 10 * 1000 // 10 seconds
    });

      octaneService = new OctaneService(
        connection,
        jupiterQuoteApi,
        createTestKeypair(),
        new PublicKey("11111111111111111111111111111111"),
        100,
        0,
        15,
        cache
      );
    } catch (error) {
      console.error('Error in test setup:', error);
      if (error instanceof Error) {
        console.error('Error message:', error.message);
        console.error('Stack trace:', error.stack);
      }
      throw error;
    }
  });

  it("should get a valid quote for SOL to USDC", async () => {
    const quoteRequest = {
      inputMint: "So11111111111111111111111111111111111111112", // SOL
      outputMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", // USDC
      amount: 100000000, // 0.1 SOL
      slippageBps: 50,
      onlyDirectRoutes: false,
      asLegacyTransaction: false,
    };

    try {
      console.log("\nGetting quote for SOL -> USDC:");
      console.log("Input: 0.1 SOL");
      console.log("Request:", quoteRequest);
      
      const quote = await octaneService.getQuote(quoteRequest);
      
      console.log("Quote response:");
      console.log({
        inputMint: quote.inputMint,
        outputMint: quote.outputMint,
        inAmount: `${Number(quote.inAmount) / 1e9} SOL`,
        outAmount: `${Number(quote.outAmount) / 1e6} USDC`,
        price: `${(Number(quote.outAmount) / 1e6) / (Number(quote.inAmount) / 1e9)} USDC/SOL`,
        priceImpactPct: quote.priceImpactPct,
      });

      console.log("\nRoute Plan:");
      quote.routePlan.forEach((step, index) => {
        console.log(`\nStep ${index + 1}:`);
        console.log({
          protocol: step.swapInfo.label,
          inputMint: step.swapInfo.inputMint,
          outputMint: step.swapInfo.outputMint,
          inAmount: step.swapInfo.inAmount,
          outAmount: step.swapInfo.outAmount,
          fee: step.swapInfo.feeAmount,
          percent: `${step.percent}%`
        });
      });

      expect(quote).toBeDefined();
      expect(quote.inputMint).toBe(quoteRequest.inputMint);
      expect(quote.outputMint).toBe(quoteRequest.outputMint);
      expect(quote.inAmount).toBe(quoteRequest.amount.toString());
      expect(Number(quote.outAmount)).toBeGreaterThan(0);
    } catch (error) {
      console.error('Error getting SOL->USDC quote:');
      if (error instanceof AxiosError) {
        console.error('Status:', error.response?.status);
        console.error('Status Text:', error.response?.statusText);
        console.error('Response Headers:', error.response?.headers);
        console.error('Response Data:', JSON.stringify(error.response?.data, null, 2));
      } else if (error instanceof Error) {
        console.error('Error message:', error.message);
        console.error('Stack trace:', error.stack);
      }
      throw error;
    }
  }, 30000);

  it("should get a valid quote for USDC to SOL", async () => {
    const quoteRequest = {
      inputMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", // USDC
      outputMint: "So11111111111111111111111111111111111111112", // SOL
      amount: 1000000, // 1 USDC
      slippageBps: 50,
      onlyDirectRoutes: false,
      asLegacyTransaction: false,
    };

    console.log("\nGetting quote for USDC -> SOL:");
    console.log("Input: 1 USDC");
    
    const quote = await octaneService.getQuote(quoteRequest);
    
    console.log("Quote response:");
    console.log({
      inputMint: quote.inputMint,
      outputMint: quote.outputMint,
      inAmount: `${Number(quote.inAmount) / 1e6} USDC`,
      outAmount: `${Number(quote.outAmount) / 1e9} SOL`,
      price: `${(Number(quote.inAmount) / 1e6) / (Number(quote.outAmount) / 1e9)} USDC/SOL`,
      priceImpactPct: quote.priceImpactPct,
    });

    console.log("\nRoute Plan:");
    quote.routePlan.forEach((step, index) => {
      console.log(`\nStep ${index + 1}:`);
      console.log({
        protocol: step.swapInfo.label,
        inputMint: step.swapInfo.inputMint,
        outputMint: step.swapInfo.outputMint,
        inAmount: step.swapInfo.inAmount,
        outAmount: step.swapInfo.outAmount,
        fee: step.swapInfo.feeAmount,
        percent: `${step.percent}%`
      });
    });

    expect(quote).toBeDefined();
    expect(quote.inputMint).toBe(quoteRequest.inputMint);
    expect(quote.outputMint).toBe(quoteRequest.outputMint);
    expect(quote.inAmount).toBe(quoteRequest.amount.toString());
    expect(Number(quote.outAmount)).toBeGreaterThan(0);
  }, 30000);
}); 