import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './live-e2e', workers: 1,
  use: {
    baseURL: process.env.FIRSTAID_ADMIN_TEST_URL || 'http://127.0.0.1:5173',
    channel: process.env.PLAYWRIGHT_CHANNEL,
    trace: 'retain-on-failure',
  },
});
