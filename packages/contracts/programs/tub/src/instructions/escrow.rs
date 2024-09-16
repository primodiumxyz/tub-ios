use anchor_lang::prelude::*;
use anchor_lang::system_program;

#[account]
pub struct EscrowAccount {
    pub balance: u64,
    pub authority: Pubkey,
}

pub const ESCROW_SEED: &[u8] = b"escrow";

#[derive(Accounts)]
pub struct InitializeEscrow<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + 8 + 32, // discriminator + balance + authority
        seeds = [ESCROW_SEED],
        bump,

    )]
    pub escrow_account: Account<'info, EscrowAccount>,

    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn initialize_escrow(ctx: Context<InitializeEscrow>) -> Result<()> {
    let escrow_account = &mut ctx.accounts.escrow_account;
    escrow_account.balance = 0;
    escrow_account.authority = ctx.accounts.authority.key();
    Ok(())
}

#[derive(Accounts)]
pub struct WithdrawFunds<'info> {
    #[account(mut, has_one = authority)]
    pub escrow_account: Account<'info, EscrowAccount>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn withdraw_funds(ctx: Context<WithdrawFunds>, amount: u64) -> Result<()> {
    let escrow_account = &mut ctx.accounts.escrow_account;

    if amount > escrow_account.balance {
        return Err(ErrorCode::InsufficientFunds.into());
    }

    escrow_account.balance = escrow_account.balance.checked_sub(amount).unwrap();

    // Transfer SOL from escrow account to authority
    system_program::transfer(
        CpiContext::new(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: escrow_account.to_account_info(),
                to: ctx.accounts.authority.to_account_info(),
            },
        ),
        amount,
    )?;

    Ok(())
}



#[error_code]
pub enum ErrorCode {
    #[msg("Insufficient funds in the escrow account")]
    InsufficientFunds,
}