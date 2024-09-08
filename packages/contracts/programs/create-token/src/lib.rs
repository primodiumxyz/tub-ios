#![allow(clippy::result_large_err)]

use anchor_lang::prelude::*;

pub mod instructions;
use instructions::*;

declare_id!("C1EHDWDzfcBjun8fTG8xa1oWR3Kv7t91mtkUcGT86QyK");

#[program]
pub mod create_token {
    use super::*;

    pub fn create_token(
        ctx: Context<CreateToken>,
        token_name: String,
        token_symbol: String,
        token_uri: String,
    ) -> Result<()> {
        create::create_token(ctx, token_name, token_symbol, token_uri)
    }

    pub fn mint_token(ctx: Context<MintToken>, amount: u64) -> Result<()> {
        mint::mint_token(ctx, amount)
    }
}
