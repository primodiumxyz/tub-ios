#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

pub mod instructions;
use instructions::*;

declare_id!("33k6geABgPqmEkAVQAHPpc2pnUMRP2yq8pSRNPsYy8bv");

#[program]
pub mod tub {
    use super::*;

     pub fn initialize(ctx: Context<InitializeEscrow>) -> Result<()> {
        escrow::initialize_escrow(ctx)
    }

    // creates a token and a metadata account
    // mints _lamports * 100_000 tokens
    // transfers _lamports lamports from the user to the token program
    pub fn create_token(
        ctx: Context<CreateToken>,
        token_name: String,
        token_symbol: String,
        token_uri: String,
        _lamports: u64
    ) -> Result<()> {
        create::create_token(ctx, token_name, token_symbol, token_uri, _lamports)
    }

    // mints _amount tokens to the caller
    // caller must be the mint authority
    pub fn mint_token(ctx: Context<MintToken>, amount: u64) -> Result<()> {
        mint::mint_token(ctx, amount)
    }

    pub fn withdraw_funds(ctx: Context<WithdrawFunds>, amount: u64) -> Result<()> {
        escrow::withdraw_funds(ctx, amount)
    }
}
