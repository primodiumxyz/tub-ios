#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

pub mod instructions;
// use instructions::{CreateToken, create, MintToken, mint };
use instructions::*;

declare_id!("4PkPposur5Y4XZXTVQ8XrRy2UVrN6NYNT1PeoneUDqSL");

#[program]
pub mod tub {
    use super::*;

    // creates a token and a metadata account
    // mints _lamports * 100_000 tokens
    // transfers _lamports lamports from the user to the token program
    pub fn init_token(
        ctx: Context<InitToken>,
        token_name: String,
        token_symbol: String,
        token_uri: String,
        _lamports: u64
    ) -> Result<()> {
        init::init_token(ctx, token_name, token_symbol, token_uri, _lamports)
    }

    // vanilla create token program call
    pub fn create_token(
        ctx: Context<CreateToken>,
        token_name: String,
        token_symbol: String,
        token_uri: String,
    ) -> Result<()> {
        create::create_token(ctx, token_name, token_symbol, token_uri)
    }

    // mints _amount tokens to the caller
    // caller must be the mint authority
    pub fn mint_token(ctx: Context<MintToken>, amount: u64) -> Result<()> {
        mint::mint_token(ctx, amount)
    }
}
