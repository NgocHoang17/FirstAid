import { describe, expect, it } from 'vitest';
import { AdminApi } from './api';
import { createDemoTransport } from './demo';

describe('development contract fixtures', () => {
  it('requires a session, supports filtering and protects references', async () => {
    const api = new AdminApi(createDemoTransport());
    await expect(api.me()).rejects.toMatchObject({ status: 401 });
    await api.login('demo', 'demo');
    expect((await api.list('articles', { page: 2, page_size: 10 })).items).toHaveLength(10);
    const all = await api.all('articles'); const a = all[0];
    expect((await api.list('articles', { category_id: a.category_id })).items.every(x => x.category_id === a.category_id)).toBe(true);
    await expect(api.remove('categories', a.category_id)).rejects.toMatchObject({ code: 'RESOURCE_IN_USE' });
    await expect(api.remove('sources', a.references[0].source_id)).rejects.toMatchObject({ code: 'RESOURCE_IN_USE' });
    await api.logout(); await expect(api.all('articles')).rejects.toMatchObject({ status: 401 });
  });
  it('returns public edits to draft, requires renewed confirmation and blocks stale revisions', async () => {
    const api = new AdminApi(createDemoTransport()); await api.login('demo', 'demo');
    const a = (await api.all('articles'))[0];
    const draft = await api.save('articles', { ...a, title: `${a.title} · test` });
    expect(draft.status).toBe('DRAFT'); expect(draft.content_checked).toBe(false); expect(draft.checked_at).toBeNull();
    await expect(api.publish(draft.id, draft.content_revision, true)).rejects.toMatchObject({ code: 'CONTENT_NOT_READY' });
    await expect(api.save('articles', a)).rejects.toMatchObject({ code: 'CONTENT_CONFLICT' });
    const checked = await api.save('articles', { ...draft, content_checked: true });
    const published = await api.publish(checked.id, checked.content_revision, true);
    expect(published.status).toBe('PUBLISHED');
    const freshApi = new AdminApi(createDemoTransport()); await freshApi.login('demo', 'demo');
    expect((await freshApi.get('articles', a.id)).title).toBe(a.title);
  });
});
