use anchor_lang::prelude::*;

declare_id!("HGf7R9nd1HbbsSfUCgpejzF5RckRyS9eDDi61x39qQtQ");

#[program]
pub mod tub {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter = &ctx.accounts.counter;
        msg!("Counter account created! Current count: {}", counter.count);
        Ok(())
    }

    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        msg!("Previous counter: {}", counter.count);

        counter.count = counter.count.checked_add(1).unwrap();
        msg!("Counter incremented! New count: {}", counter.count);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub user: Signer<'info>,

    #[account(
        init,
        payer = user,
        space = 8 + 8
    )]
    pub counter: Account<'info, Counter>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Increment<'info> {
    #[account(mut)]
    pub counter: Account<'info, Counter>,
}

#[account]
pub struct Counter {
    pub count: u64,
}
