import { beforeAll, afterAll, afterEach, vi } from 'vitest';
import { createAppRouter } from '../src/createAppRouter';
import { TubService } from '../src/TubService';

beforeAll(() => {
  // Add any global setup here
});

afterAll(() => {
  // Add any global teardown here
});

afterEach(() => {
  // Clean up after each test
});

// Mock TubService
vi.mock('../src/TubService', () => {
  return {
    TubService: vi.fn().mockImplementation(() => ({
      getStatus: vi.fn().mockReturnValue({ status: 200 }),
      incrementCall: vi.fn(),
      subscribeToCounter: vi.fn(),
      unsubscribeFromCounter: vi.fn(),
    })),
  };
});