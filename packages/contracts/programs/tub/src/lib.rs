use anchor_lang::prelude::*;

declare_id!("4NFpe3u1BxcMWhZD8AKqUfWhBA73dJ9WZAP36SexG4d8");

#[program]
pub mod tub {
    use super::*;
 
    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        counter.bump = ctx.bumps.counter; // store bump seed in `Counter` account
        msg!("Counter account created! Current count: {}", counter.count);
        msg!("Counter bump: {}", counter.bump);
        Ok(())
    }
 
    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter = &mut ctx.accounts.counter;
        msg!("Previous counter: {}", counter.count);
        counter.count = counter.count.checked_add(1).unwrap();
        msg!("Counter incremented! Current count: {}", counter.count);
        Ok(())
    }
}
 
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
 
    // Create and initialize `Counter` account using a PDA as the address
    #[account(
        init,
        seeds = [b"randomSeed"], // optional seeds for pda
        bump,                 // bump seed for pda
        payer = user,
        space = 8 + Counter::INIT_SPACE
    )]
    pub counter: Account<'info, Counter>,
    pub system_program: Program<'info, System>,
}
 
#[derive(Accounts)]
pub struct Increment<'info> {
    // The address of the `Counter` account must be a PDA derived with the specified `seeds`
    #[account(
        mut,
        seeds = [b"randomSeed"], // optional seeds for pda
        bump = counter.bump,  // bump seed for pda stored in `Counter` account
    )]
    pub counter: Account<'info, Counter>,
}
 
#[account]
#[derive(InitSpace)]
pub struct Counter {
    pub count: u64, // 8 bytes
    pub bump: u8,   // 1 byte
}

