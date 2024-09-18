use anchor_lang::prelude::*;
use anchor_lang::system_program;

#[account]
pub struct TreasuryAccount {
    pub balance: u64,
    pub authority: Pubkey,
}

pub const TREASURY_SEED: &[u8] = b"treasury";

#[derive(Accounts)]
pub struct InitializeTreasury<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + 8 + 32, // discriminator + balance + authority
        seeds = [TREASURY_SEED],
        bump,

    )]
    pub treasury_account: Account<'info, TreasuryAccount>,

    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn initialize_treasury(ctx: Context<InitializeTreasury>) -> Result<()> {
    let treasury_account = &mut ctx.accounts.treasury_account;
    treasury_account.balance = 0;
    treasury_account.authority = ctx.accounts.authority.key();
    Ok(())
}

#[derive(Accounts)]
pub struct WithdrawFunds<'info> {
    #[account(mut, has_one = authority)]
    pub treasury_account: Account<'info, TreasuryAccount>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn withdraw_funds(ctx: Context<WithdrawFunds>, amount: u64) -> Result<()> {
    let treasury_account = &mut ctx.accounts.treasury_account;

    if amount > treasury_account.balance {
        return Err(ErrorCode::InsufficientFunds.into());
    }

    treasury_account.balance = treasury_account.balance.checked_sub(amount).unwrap();

    // Transfer SOL from treasury account to authority
    system_program::transfer(
        CpiContext::new(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: treasury_account.to_account_info(),
                to: ctx.accounts.authority.to_account_info(),
            },
        ),
        amount,
    )?;

    Ok(())
}



#[error_code]
pub enum ErrorCode {
    #[msg("Insufficient funds in the treasury account")]
    InsufficientFunds,
}