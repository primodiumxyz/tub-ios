declare module '@primodiumxyz/octane-core' {
    import { Connection, Keypair, Transaction } from "@solana/web3.js";
    import { Cache } from 'cache-manager';

    export const core: {
        validateInstructions: (transaction: Transaction, feePayer: Keypair) => Promise<void>;
    };

    export function signWithTokenFee(
        connection: Connection,
        transaction: Transaction,
        feePayer: Keypair,
        maxSignatures: number,
        lamportsPerSignature: number,
        tokenFees: any[],
        cache: Cache,
        sameSourceTimeout: number
    ): Promise<{ signature: string }>;

    export function createAccountIfTokenFeePaid(
        connection: Connection,
        transaction: Transaction,
        feePayer: Keypair,
        maxSignatures: number,
        lamportsPerSignature: number,
        tokenFees: any[],
        cache: Cache,
        sameSourceTimeout: number
    ): Promise<{ signature: string }>;
} 