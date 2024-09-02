#![allow(clippy::result_large_err)]

use {
    anchor_lang::prelude::*,
    anchor_spl::{
        associated_token::AssociatedToken,
        metadata::{
            create_metadata_accounts_v3,
            CreateMetadataAccountsV3, 
            Metadata,
            mpl_token_metadata::types::DataV2,
        },
        token::{Mint, Token, TokenAccount},
    },
    std::mem::size_of,
};

declare_id!("6aLsHmmAB7GNbQn6czDjBMwjre5gFi8NQmtMk3SireBE");

#[program]
pub mod create_token {
    use super::*;

    pub fn create_token_mint_with_amount(
        ctx: Context<CreateTokenMintWithAmount>,
        token_decimals: u8,
        token_name: String,
        token_symbol: String,
        token_uri: String,
        amount_lamports: u64,
    ) -> Result<()> {
        // Calculate the minimum balance for rent exemption
        const MAX_NAME_LENGTH: usize = 32;
        const MAX_SYMBOL_LENGTH: usize = 10;
        const MAX_URI_LENGTH: usize = 200;
        const MAX_METADATA_LEN: usize = 1 + 32 + 32 + MAX_NAME_LENGTH + MAX_SYMBOL_LENGTH + MAX_URI_LENGTH + 2 + 1 + 1 + 198;

        let metadata_space = MAX_METADATA_LEN;

        let rent = Rent::get()?;
        let mint_space = Mint::LEN;
        let associated_token_space = TokenAccount::LEN;
        let escrow_space = 8 + size_of::<Pubkey>() + size_of::<Pubkey>();

        let minimum_balance = rent.minimum_balance(mint_space)
            .checked_add(rent.minimum_balance(metadata_space))
            .and_then(|sum| sum.checked_add(rent.minimum_balance(associated_token_space)))
            .and_then(|sum| sum.checked_add(rent.minimum_balance(escrow_space)))
            .ok_or(ProgramError::ArithmeticOverflow)?;

        // Verify the transferred amount
        if ctx.accounts.payer.lamports() < amount_lamports.checked_add(minimum_balance).ok_or(ProgramError::ArithmeticOverflow)? {
            return Err(ProgramError::InsufficientFunds.into());
        }

        // Calculate token amount based on 10000 tokens per SOL
        let tokens_per_sol = 10000;
        let raw_token_amount = amount_lamports.checked_mul(tokens_per_sol).ok_or(ProgramError::ArithmeticOverflow)?;
        
        // Adjust for token decimals
        let adjusted_token_amount = raw_token_amount.checked_mul(10u64.pow(token_decimals as u32)).ok_or(ProgramError::ArithmeticOverflow)?;

        // Create metadata account
        let metadata_account_info = &ctx.accounts.metadata_account;
        let mint_account_info = &ctx.accounts.mint_account;
        create_metadata_accounts_v3(
            CpiContext::new(
                ctx.accounts.token_metadata_program.to_account_info(),
                CreateMetadataAccountsV3 {
                    metadata: metadata_account_info.to_account_info(),
                    mint: mint_account_info.to_account_info(),
                    mint_authority: ctx.accounts.payer.to_account_info(),
                    payer: ctx.accounts.payer.to_account_info(),
                    update_authority: ctx.accounts.payer.to_account_info(),
                    system_program: ctx.accounts.system_program.to_account_info(),
                    rent: ctx.accounts.rent.to_account_info(),
                },
            ),
            DataV2 {
                name: token_name,
                symbol: token_symbol,
                uri: token_uri,
                seller_fee_basis_points: 0,
                creators: None,
                collection: None,
                uses: None,
            },
            true,
            true,
            None,
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

        // Transfer SOL from payer to escrow account
        let transfer_instruction = anchor_lang::system_program::Transfer {
            from: ctx.accounts.payer.to_account_info(),
            to: ctx.accounts.escrow_account.to_account_info(),
        };
        anchor_lang::system_program::transfer(
            CpiContext::new(
                ctx.accounts.system_program.to_account_info(),
                transfer_instruction,
            ),
            amount_lamports,
        )?;

        // Initialize the escrow account
        ctx.accounts.escrow_account.mint = ctx.accounts.mint_account.key();
        ctx.accounts.escrow_account.authority = ctx.accounts.payer.key();

        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(token_decimals: u8)]
pub struct CreateTokenMintWithAmount<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    #[account(
        mut,
        seeds = [b"metadata", token_metadata_program.key().as_ref(), mint_account.key().as_ref()],
        bump,
        seeds::program = token_metadata_program.key(),
    )]
    /// CHECK: Metadata account, initialized in instruction
    pub metadata_account: UncheckedAccount<'info>,

    #[account(
        init,
        payer = payer,
        mint::decimals = token_decimals,
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

    pub token_metadata_program: Program<'info, Metadata>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[account]
pub struct EscrowAccount {
    pub mint: Pubkey,
    pub authority: Pubkey,
}