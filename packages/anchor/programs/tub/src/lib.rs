use anchor_lang::prelude::*;

declare_id!("HGf7R9nd1HbbsSfUCgpejzF5RckRyS9eDDi61x39qQtQ");

#[program]
pub mod tub {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
