import { describe, it, expect, beforeAll } from 'vitest';
import { TubService } from '../src/TubService';
import { OctaneService } from '../src/OctaneService';
import { Connection, Keypair, PublicKey } from '@solana/web3.js';
import { createJupiterApiClient } from '@jup-ag/api';
import { MockPrivyClient } from './helpers/MockPrivyClient';
import { Codex } from '@codex-data/sdk';
import { createClient as createGqlClient } from '@tub/gql';
import { config } from 'dotenv';
import bs58 from 'bs58';

config({ path: "../../.env" });

describe('TubService Integration Test', () => {
  let tubService: TubService;
  let userKeypair: Keypair;
  let mockJwtToken: string;
  
  beforeAll(async () => {
    try {
      // Setup connection to Solana mainnet
      const connection = new Connection(process.env.QUICKNODE_MAINNET_URL ?? 'https://api.mainnet-beta.solana.com');
      
      // Setup Jupiter API client
      const jupiterQuoteApi = createJupiterApiClient({
        basePath: process.env.JUPITER_URL
      });

      // Create cache for OctaneService
      const cache = await (await import('cache-manager')).caching({
        store: 'memory',
        max: 100,
        ttl: 10 * 1000 // 10 seconds
      });

      // Create test fee payer keypair
      const feePayerKeypair = Keypair.fromSecretKey(
        bs58.decode(process.env.FEE_PAYER_PRIVATE_KEY!)
      );

      // Create test user keypair
      userKeypair = Keypair.generate();
      mockJwtToken = 'test_jwt_token';

      // Initialize services
      const octaneService = new OctaneService(
        connection,
        jupiterQuoteApi,
        feePayerKeypair,
        new PublicKey(process.env.OCTANE_TRADE_FEE_RECIPIENT!),
        Number(process.env.OCTANE_BUY_FEE),
        0, // sell fee
        15, // min trade size
        cache
      );

      const gqlClient = (await createGqlClient({
        url: 'http://localhost:8080/v1/graphql',
        hasuraAdminSecret: 'password'
      })).db;

      const codexSdk = new Codex(process.env.CODEX_API_KEY!);

      // Create mock Privy client with our test wallet
      const mockPrivyClient = new MockPrivyClient(userKeypair.publicKey.toString());

      tubService = new TubService(
        gqlClient,
        mockPrivyClient as any,
        codexSdk,
        octaneService
      );

    } catch (error) {
      console.error('Error in test setup:', error);
      throw error;
    }
  });

  it('should complete a full USDC to SOL swap flow', async () => {
    try {
      console.log('\nStarting USDC to SOL swap flow test');
      console.log('User public key:', userKeypair.publicKey.toBase58());

      // Get the swap transaction
      console.log('\nGetting 1 USDC to SOL swap transaction...');
      const swapResponse = await tubService.get1USDCToSOLTransaction(mockJwtToken);
      
      console.log('Received swap response:', {
        hasFee: swapResponse.hasFee,
        transactionLength: swapResponse.transactionBase64.length
      });

    //   // Sign the transaction
    //   const transaction = Buffer.from(swapResponse.transactionBase64, 'base64');
    //   const signature = bs58.encode(userKeypair.sign(transaction));

    //   console.log('\nSigning and sending transaction...');
    //   const result = await tubService.signAndSendTransaction(
    //     mockJwtToken,
    //     signature,
    //     swapResponse.transactionBase64
    //   );

    //   console.log('Transaction result:', result);

    //   expect(result).toBeDefined();
    //   expect(result.signature).toBeDefined();
      
    } catch (error) {
      console.error('Error in swap flow test:', error);
      throw error;
    }
  }, 30000);
}); 