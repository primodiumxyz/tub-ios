import { describe, it, expect, beforeEach } from 'vitest';
import { createAppRouter } from '../src/createAppRouter';
import { TubService } from '../src/TubService';
import { inferProcedureInput } from '@trpc/server';
import type { AppRouter } from '../src/createAppRouter';

describe('createAppRouter', () => {
  let appRouter: AppRouter;
  let tubService: TubService;

  beforeEach(() => {
    tubService = new TubService({} as any); // Mock Core
    appRouter = createAppRouter();
  });

  it('should have getStatus procedure', async () => {
    const caller = appRouter.createCaller({ tubService });
    const result = await caller.getStatus();
    expect(result).toEqual({ status: 200 });
  });

  it('should have incrementCall procedure', async () => {
    const caller = appRouter.createCaller({ tubService });
    await caller.incrementCall();
    expect(tubService.incrementCall).toHaveBeenCalled();
  });

  it('should have onCounterUpdate subscription', () => {
    const procedure = appRouter._def.procedures['onCounterUpdate'];
    expect(procedure).toBeDefined();
    expect(procedure._type).toBe('subscription');
  });
});