import { expect, test } from '@playwright/test';

test('real backend login, catalogue search and logout', async ({ page }) => {
  const username = process.env.FIRSTAID_TEST_ADMIN_USERNAME;
  const password = process.env.FIRSTAID_TEST_ADMIN_PASSWORD;
  if (!username || !password) throw new Error('Set FIRSTAID_TEST_ADMIN_USERNAME and FIRSTAID_TEST_ADMIN_PASSWORD for a seeded local backend.');

  await page.goto('/');
  await expect(page.getByText('DEMO LOCAL', { exact: false })).toHaveCount(0);
  await page.getByLabel('Tên đăng nhập', { exact: true }).fill(username);
  await page.getByLabel('Mật khẩu', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Bài sơ cứu', exact: true })).toBeVisible();

  await page.getByRole('navigation').getByRole('button', { name: 'Danh mục', exact: true }).click();
  await page.getByLabel('Tìm kiếm', { exact: true }).fill('FA01');
  await expect(page.getByText('Hiển thị 1–1 trong 1 kết quả')).toBeVisible();
  await page.getByRole('navigation').getByRole('button', { name: 'Nguồn tài liệu', exact: true }).click();
  await page.getByLabel('Tìm kiếm', { exact: true }).fill('cam nang');
  await expect(page.getByText('Hiển thị 1–1 trong 1 kết quả')).toBeVisible();
  await expect(page.getByRole('button', { name: 'CẨM NANG SƠ CẤP CỨU', exact: true })).toBeVisible();

  await page.getByRole('button', { name: 'Đăng xuất', exact: true }).click();
  const response = page.waitForResponse(r => r.url().endsWith('/api/v1/admin/auth/logout') && r.request().method() === 'POST');
  await page.getByRole('dialog').getByRole('button', { name: 'Đăng xuất', exact: true }).click();
  expect((await response).status()).toBe(204);
  await expect(page.getByRole('heading', { name: 'Đăng nhập quản trị', exact: true })).toBeVisible();
  expect((await page.request.get('/api/v1/admin/auth/me')).status()).toBe(401);
});
