import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { AdminApi, ApiError } from './api';
import { Editor } from './Editor';
import library from '../../mobile/assets/content/reference_library.json';
import { blankEntity, type Article, type Category, type Source } from './models';

function setup(error: ApiError) {
  const api = new AdminApi(); const a = structuredClone(library.articles[0]) as Article;
  a.status = 'DRAFT';
  vi.spyOn(api, 'get').mockResolvedValue(a);
  vi.spyOn(api, 'all').mockImplementation(async resource => resource === 'categories' ? library.categories as Category[] : library.sources as Source[]);
  vi.spyOn(api, 'save').mockRejectedValue(error);
  vi.spyOn(api, 'refreshCsrf').mockResolvedValue();
  const confirm = vi.fn(); const dirty = vi.fn();
  render(<Editor api={api} resource="articles" id={a.id} back={vi.fn()} confirm={confirm} setDirty={dirty} notify={vi.fn()}/>);
  return { api, confirm, dirty };
}
describe('editor failure recovery', () => {
  it('keeps unsaved content on conflict and requires confirmation before loading another revision', async () => {
    const { api, confirm } = setup(new ApiError(409, 'CONTENT_CONFLICT', 'Changed'));
    const user = userEvent.setup();
    const title = await screen.findByLabelText('Tiêu đề'); await user.clear(title); await user.type(title, 'Bản nhập cần giữ');
    await user.click(screen.getByRole('button', { name: 'Lưu bản nháp' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('không tự ghi đè');
    expect(title).toHaveValue('Bản nhập cần giữ');
    await user.click(screen.getByRole('button', { name: 'Tải bản mới' }));
    expect(confirm).toHaveBeenCalledOnce(); expect(api.get).toHaveBeenCalledTimes(1);
  });
  it('refreshes CSRF without resubmitting a write or clearing the form', async () => {
    const { api } = setup(new ApiError(403, 'CSRF_INVALID', 'Invalid'));
    const user = userEvent.setup();
    const title = await screen.findByLabelText('Tiêu đề'); await user.clear(title); await user.type(title, 'Giữ sau lỗi CSRF');
    await user.click(screen.getByRole('button', { name: 'Lưu bản nháp' }));
    await user.click(await screen.findByRole('button', { name: 'Làm mới phiên' }));
    expect(api.refreshCsrf).toHaveBeenCalledOnce(); expect(api.save).toHaveBeenCalledOnce(); expect(title).toHaveValue('Giữ sau lỗi CSRF');
    await waitFor(() => expect(screen.queryByRole('alert')).not.toBeInTheDocument());
  });
  it('preserves new step ordering and permits a partial draft with empty optional sections', async () => {
    const api = new AdminApi(); vi.spyOn(api, 'all').mockImplementation(async resource => resource === 'categories' ? library.categories as Category[] : library.sources as Source[]);
    const save = vi.spyOn(api, 'save').mockImplementation(async (_resource, value) => ({ ...blankEntity('articles'), ...value, id: 'created' }));
    const user = userEvent.setup();
    render(<Editor api={api} resource="articles" id="new" back={vi.fn()} confirm={vi.fn()} setDirty={vi.fn()} notify={vi.fn()}/>);
    await user.type(await screen.findByLabelText('Tiêu đề'), 'Bài fixture');
    await user.selectOptions(screen.getByLabelText('Danh mục'), library.categories[0].id);
    await user.type(screen.getByLabelText('Đường dẫn (slug)'), 'draft_test');
    await user.type(screen.getByLabelText('Mã biến thể'), 'test');
    await user.click(screen.getByRole('button', { name: 'Thêm bước' }));
    await user.type(screen.getByLabelText('Tên bước 1'), 'Bước thử nghiệm');
    await user.type(screen.getByLabelText('Hướng dẫn bước 1'), 'Fixture, không hướng dẫn sơ cứu.');
    await user.click(screen.getByText('Minh họa và khả năng tiếp cận'));
    await user.type(screen.getByLabelText('Mô tả hình'), 'Mô tả có khoảng trắng');
    await user.click(screen.getByRole('button', { name: 'Lưu bản nháp' }));
    await waitFor(() => expect(save).toHaveBeenCalledOnce());
    const payload = save.mock.calls[0][1] as Article; expect(payload.steps[0].position).toBe(1); expect(payload.recognition).toEqual([]);
    expect(payload.steps[0].alt_text).toBe('Mô tả có khoảng trắng');
  });
});
