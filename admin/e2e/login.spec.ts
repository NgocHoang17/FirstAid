import { expect, test } from '@playwright/test';

for (const width of [320, 768, 1440]) {
  test('đăng nhập ở chiều rộng ' + width, async ({ page }) => {
    await page.setViewportSize({ width, height: 740 });
    await page.goto('/');
    const submit = page.getByRole('button', { name: 'Đăng nhập', exact:true });
    await expect(submit).toBeDisabled();
    await page.getByLabel('Tên đăng nhập', {exact:true}).fill('demo');
    const password = page.getByLabel('Mật khẩu', {exact:true});
    await password.fill('sai');
    await page.getByRole('button',{name:'Hiện mật khẩu'}).click();
    await expect(password).toHaveAttribute('type','text');
    await submit.click();
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(password).toHaveValue('sai');
    expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(width);
    await password.fill('demo');
    await password.press('Enter');
    await expect(page.getByRole('heading',{name:'Bài sơ cứu',exact:true})).toBeVisible();
  });
}
