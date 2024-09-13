#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

pub mod instructions;
use instructions::*;

declare_id!("4PkPposur5Y4XZXTVQ8XrRy2UVrN6NYNT1PeoneUDqSL");

#[program]
pub mod tub_token {
    use super::*;

    pub fn create_tub_token(
        ctx: Context<CreateToken>,
        token_name: String,
        token_symbol: String,
        token_uri: String,
        lamports: u64
    ) -> Result<()> {
        create::create_token(ctx, token_name, token_symbol, token_uri, lamports)
    }

    pub fn mint_token(ctx: Context<MintToken>, amount: u64) -> Result<()> {
        mint::mint_token(ctx, amount)
    }
}
