import { beforeAll, afterAll, afterEach } from 'vitest';

beforeAll(async () => {
  const maxAttempts = 20;
  const retryInterval = 5000; // 1 second
  const timeout = 5000; // 5 seconds

  for (let i = 0; i < maxAttempts; i++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      const response = await fetch('http://localhost:8080/healthz?strict=true', {
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        console.log('Hasura service is healthy');
        // wait for 5 seconds for seeding to complete if retry count is more than 1
        if (i > 0) {
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
        return;
      }
    } catch (error) {
      console.warn(`Attempt ${i + 1}/${maxAttempts}: Hasura service is not reachable yet. Retrying...`);
    }

    if (i < maxAttempts - 1) {
      await new Promise(resolve => setTimeout(resolve, retryInterval));
    }
  }

  throw new Error('Hasura service is not available. Please ensure it\'s running with `pnpm hasura-up` and try again.');
}, 1000 * 60);

afterAll(() => {
  // Add any global teardown here
});

afterEach(() => {
  // Clean up after each test
});

