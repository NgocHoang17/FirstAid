import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { expect, it, vi } from 'vitest';
import { AdminApi, ApiError } from './api';
import { App } from './App';
import library from '../../mobile/assets/content/reference_library.json';
import type { Article, Category, Source } from './models';

it('keeps the editor mounted through session expiration and a successful re-login', async () => {
  const api = new AdminApi(); const user = userEvent.setup();
  const admin = { id: 'user', username: 'admin', role: 'ADMIN' as const };
  const article = { ...structuredClone(library.articles[0]), status: 'DRAFT' } as Article;
  vi.spyOn(api, 'me').mockResolvedValue(admin); vi.spyOn(api, 'login').mockResolvedValue(admin);
  vi.spyOn(api, 'list').mockResolvedValue({ items: [article], total: 1, page: 1, page_size: 10 });
  vi.spyOn(api, 'get').mockResolvedValue(article);
  vi.spyOn(api, 'all').mockImplementation(async resource => resource === 'categories' ? library.categories as Category[] : library.sources as Source[]);
  vi.spyOn(api, 'save').mockImplementation(async () => { api.onUnauthorized?.(); throw new ApiError(401, 'AUTH_REQUIRED', 'Expired'); });
  render(<App api={api}/>);
  await user.click(await screen.findByRole('button', { name: article.title }));
  const title = await screen.findByLabelText('Tiêu đề'); await user.clear(title); await user.type(title, 'Bản nhập khi hết phiên');
  await user.click(screen.getByRole('button', { name: 'Lưu bản nháp' }));
  const dialog = await screen.findByRole('dialog', { name: 'Đăng nhập lại' });
  await user.type(within(dialog).getByLabelText('Tên đăng nhập'), 'admin'); await user.type(within(dialog).getByLabelText('Mật khẩu'), 'test-only');
  await user.click(within(dialog).getByRole('button', { name: 'Đăng nhập' }));
  expect(await screen.findByText('Đã khôi phục phiên. Có thể thử lại thao tác.')).toBeInTheDocument();
  expect(title).toHaveValue('Bản nhập khi hết phiên'); expect(api.save).toHaveBeenCalledOnce();
});
