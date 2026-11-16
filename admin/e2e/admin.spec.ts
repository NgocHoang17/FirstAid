import { expect, test } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Tên đăng nhập', { exact: true }).fill('demo');
  await page.getByLabel('Mật khẩu', { exact: true }).fill('demo');
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Bài sơ cứu', exact: true })).toBeVisible();
});
test('search, pagination, edit, preview, confirm publication and re-publish', async ({ page }) => {
  await expect(page.getByText('Hiển thị 1–10 trong 24 kết quả')).toBeVisible();
  await page.getByRole('button', { name: 'Trang tiếp', exact: true }).click();
  await expect(page.getByText('Hiển thị 11–20 trong 24 kết quả')).toBeVisible();
  await page.getByLabel('Tìm kiếm', { exact: true }).fill('CPR');
  await expect(page.getByText('Hiển thị 1–2 trong 2 kết quả')).toBeVisible();
  await page.getByRole('button', { name: 'CPR và AED ở người lớn', exact: true }).click();
  const title = page.getByLabel('Tiêu đề', { exact: true });
  await title.fill('CPR và AED ở người lớn · kiểm thử');
  await expect(page.locator('.phone-preview')).toContainText('CPR và AED ở người lớn · kiểm thử');
  await page.getByRole('button', { name: 'Đưa bước 1 xuống' }).click();
  await page.getByRole('button', { name: 'Đưa bước 2 lên' }).click();
  await page.getByRole('button', { name: 'Lưu bản nháp', exact: true }).click();
  await expect(page.getByRole('dialog')).toContainText('Xác nhận nội dung cũ sẽ bị xóa');
  await page.getByRole('button', { name: 'Lưu và chuyển về nháp', exact: true }).click();
  await expect(page.getByText('Đã lưu thay đổi.', { exact: true })).toBeVisible();
  await expect(page.getByText('Bản nháp', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Xuất bản', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Lưu xác nhận');
  await page.getByLabel('Tôi đã đối chiếu toàn bộ nội dung').check();
  await page.getByRole('button', { name: 'Lưu bản nháp', exact: true }).click();
  await expect(page.getByText('Đã lưu thay đổi.', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Xuất bản', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Xuất bản bài', exact: true }).click();
  await expect(page.getByText('Đã xuất bản', { exact: true })).toBeVisible();
});
test('guards unsaved edits and handles reference deletion without losing data', async ({ page }) => {
  await page.getByRole('button', { name: 'Tạo bài sơ cứu', exact: true }).click();
  await page.getByLabel('Tiêu đề', { exact: true }).fill('Bản nhập chưa lưu');
  await page.getByRole('navigation').getByRole('button', { name: 'Nguồn tài liệu', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Hủy', exact: true }).click();
  await expect(page.getByLabel('Tiêu đề', { exact: true })).toHaveValue('Bản nhập chưa lưu');
  await page.getByRole('navigation').getByRole('button', { name: 'Nguồn tài liệu', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Bỏ thay đổi và rời trang', exact: true }).click();
  await page.getByRole('button', { name: 'Xóa CẨM NANG SƠ CẤP CỨU', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Xóa dữ liệu', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('còn được tham chiếu');
  await expect(page.getByRole('button', { name: 'CẨM NANG SƠ CẤP CỨU', exact: true })).toBeVisible();
});
test('creates an inactive facility and validates activation, then logs out', async ({ page }) => {
  await page.getByRole('navigation').getByRole('button', { name: 'Cơ sở y tế', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm mới', exact: true }).first().click();
  await page.getByLabel('Tên cơ sở').fill('Cơ sở fixture — không liên hệ thật');
  await page.getByLabel('Mã vùng', { exact: true }).fill('VN-TEST');
  await page.getByLabel('Địa chỉ', { exact: false }).fill('Địa chỉ fixture');
  await page.getByLabel('Đang sử dụng', { exact: true }).check();
  await page.getByRole('button', { name: 'Lưu thay đổi', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Cần ngày xác minh');
  await page.getByLabel('Đang sử dụng', { exact: true }).uncheck();
  await page.getByRole('button', { name: 'Lưu thay đổi', exact: true }).click();
  await expect(page.getByText('Đã lưu thay đổi.', { exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Đăng xuất', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Đăng xuất', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Chào mừng trở lại' })).toBeVisible();
});
test('edits source metadata and category keywords with multiline input', async ({ page }) => {
  await page.getByRole('navigation').getByRole('button', { name: 'Nguồn tài liệu', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm mới', exact: true }).first().click();
  await page.getByLabel('Mã nguồn', { exact: true }).fill('TESTWEB');
  await page.getByLabel('Loại tài liệu', { exact: true }).selectOption('WEB');
  await page.getByLabel('Tên tài liệu', { exact: true }).fill('Nguồn fixture không dùng sơ cứu');
  await page.getByLabel('Đơn vị biên soạn / xuất bản', { exact: true }).fill('Test');
  await page.getByLabel('URL gốc', { exact: true }).fill('https://example.org/reference');
  await expect(page.getByLabel('Số trang PDF', { exact: true })).toHaveCount(0);
  await page.getByRole('button', { name: 'Lưu thay đổi', exact: true }).click();
  await expect(page.getByText('Đã lưu thay đổi.', { exact: true })).toBeVisible();
  await page.getByRole('navigation').getByRole('button', { name: 'Danh mục', exact: true }).click();
  await page.getByRole('button', { name: 'Chảy máu ngoài', exact: true }).click();
  await page.getByLabel('Từ khóa', { exact: true }).fill('Từ khóa thứ nhất\nTừ khóa thứ hai');
  await expect(page.getByLabel('Từ khóa', { exact: true })).toHaveValue('Từ khóa thứ nhất\nTừ khóa thứ hai');
  await page.getByRole('button', { name: 'Lưu thay đổi', exact: true }).click();
  await expect(page.getByText('Đã lưu thay đổi.', { exact: true })).toBeVisible();
});
test('keeps narrow screens within the viewport and allows horizontal table scrolling', async ({ page }) => {
  await page.getByText('Hiển thị 1–10 trong 24 kết quả').waitFor();
  for (const width of [1440, 1024, 390]) {
    await page.setViewportSize({ width, height: 900 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  }
  const table = page.locator('.table-scroll');
  expect(await table.evaluate(element => element.scrollWidth > element.clientWidth)).toBe(true);
  await page.getByRole('button', { name: 'Chảy máu ngoài', exact: true }).click();
  await expect(page.getByLabel('Tiêu đề', { exact: true })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});
