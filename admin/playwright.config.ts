import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './e2e', fullyParallel: false, workers: 1,
  use: { baseURL: 'http://127.0.0.1:5183', ...devices['Desktop Chrome'], trace: 'retain-on-failure' },
  webServer: { command: 'node node_modules/vite/bin/vite.js --mode demo --host 127.0.0.1 --port 5183 --strictPort', url: 'http://127.0.0.1:5183', reuseExistingServer: !process.env.CI },
});
