#![allow(clippy::result_large_err)]

use {
    anchor_lang::prelude::*,
    anchor_spl::{
        metadata::{
            create_metadata_accounts_v3, mpl_token_metadata::types::DataV2,
            CreateMetadataAccountsV3, Metadata,
        },
        token::{Mint, Token},
    },
};

declare_id!("6aLsHmmAB7GNbQn6czDjBMwjre5gFi8NQmtMk3SireBE");

#[program]
pub mod create_token {
    use super::*;

    pub fn create_token_mint_with_amount(
        ctx: Context<CreateTokenMintWithAmount>,
        _token_decimals: u8,
        token_name: String,
        token_symbol: String,
        token_uri: String,
        amount_lamports: u64,
    ) -> Result<()> {
        msg!("Creating metadata account...");
        msg!(
            "Metadata account address: {}",
            &ctx.accounts.metadata_account.key()
        );
        msg!("Amount in lamports: {}", amount_lamports);

        // Verify the transferred amount
        let rent = Rent::get()?;
        let minimum_balance = rent.minimum_balance(0);
        
        if ctx.accounts.payer.lamports() < amount_lamports + minimum_balance {
            return Err(ProgramError::InsufficientFunds.into());
        }

        // Calculate token amount based on 10000 tokens per SOL
        let tokens_per_sol = 10000;
        let raw_token_amount = amount_lamports.checked_mul(tokens_per_sol).ok_or(ProgramError::ArithmeticOverflow)?;
        
        // Adjust for token decimals
        let adjusted_token_amount = raw_token_amount.checked_mul(10u64.pow(_token_decimals as u32)).ok_or(ProgramError::ArithmeticOverflow)?;

        // Create token mint
        create_token_mint(
            ctx.accounts.create_token_mint_ctx(),
            _token_decimals,
            token_name,
            token_symbol,
            token_uri,
        )?;

        // Mint tokens to user's associated token account
        anchor_spl::token::mint_to(
            CpiContext::new(
                ctx.accounts.token_program.to_account_info(),
                anchor_spl::token::MintTo {
                    mint: ctx.accounts.mint_account.to_account_info(),
                    to: ctx.accounts.associated_token_account.to_account_info(),
                    authority: ctx.accounts.payer.to_account_info(),
                },
            ),
            adjusted_token_amount,
        )?;

        // Calculate the PDA for the program account
        let (pda, bump_seed) = Pubkey::find_program_address(
            &[b"escrow", ctx.accounts.mint_account.key().as_ref()],
            ctx.program_id
        );

        // Verify that the provided program_account matches the calculated PDA
        if pda != ctx.accounts.program_account.key() {
            return Err(ProgramError::InvalidAccountData.into());
        }

        // Transfer SOL from payer to program account (PDA)
        let transfer_instruction = anchor_lang::system_program::Transfer {
            from: ctx.accounts.payer.to_account_info(),
            to: ctx.accounts.program_account.to_account_info(),
        };
        anchor_lang::system_program::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.system_program.to_account_info(),
                transfer_instruction,
                &[&[b"escrow", ctx.accounts.mint_account.key().as_ref(), &[bump_seed]]],
            ),
            amount_lamports,
        )?;

        Ok(())
    }

}

#[derive(Accounts)]
#[instruction(_token_decimals: u8)]
pub struct CreateTokenMintWithAmount<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: Metadata account, initialized in instruction
    #[account(
        mut,
        seeds = [b"metadata", token_metadata_program.key().as_ref(), mint_account.key().as_ref()],
        bump,
        seeds::program = token_metadata_program.key(),
    )]
    pub metadata_account: UncheckedAccount<'info>,

    // Create new mint account
    #[account(
        init,
        payer = payer,
        mint::decimals = _token_decimals,
        mint::authority = payer.key(),
    )]
    pub mint_account: Account<'info, Mint>,

    #[account(
        init,
        payer = payer,
        associated_token::mint = mint_account,
        associated_token::authority = payer
    )]
    pub associated_token_account: Account<'info, TokenAccount>,

    #[account(
        init,
        payer = payer,
        space = 8 + 32 + 32, // 8 bytes for discriminator, 32 for mint, 32 for authority
        seeds = [b"escrow", mint_account.key().as_ref()],
        bump
    )]
    pub escrow_account: Account<'info, EscrowAccount>,

    #[account(
        mut,
        seeds = [b"escrow", mint_account.key().as_ref()],
        bump
    )]
    /// CHECK: This is the program's PDA to receive SOL payment
    pub program_account: UncheckedAccount<'info>,

    pub token_metadata_program: Program<'info, Metadata>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}
