import { describe, expect, it, vi } from 'vitest';
import { AdminApi, ApiError, type Transport } from './api';
import { blankEntity } from './models';

const ok = (data: unknown) => new Response(JSON.stringify({ data }), { status: 200 });
describe('Admin HTTP contract', () => {
  it('sends cookies and CSRF even on login, then refreshes the rotated token', async () => {
    const calls: { path: string; init?: RequestInit }[] = [];
    let token = 'before-login';
    const transport: Transport = async (path, init) => {
      calls.push({ path, init });
      if (path.endsWith('/csrf')) return ok({ token, header_name: 'X-CSRF-TOKEN' });
      if (path.endsWith('/login')) { token = 'after-login'; return ok({ id: 'id', username: 'user', role: 'ADMIN' }); }
      return new Response(null, { status: 204 });
    };
    const api = new AdminApi(transport);
    await api.login('user', 'password'); await api.logout();
    expect(calls.map(c => c.path)).toEqual(['/api/v1/admin/auth/csrf', '/api/v1/admin/auth/login', '/api/v1/admin/auth/csrf', '/api/v1/admin/auth/logout']);
    expect(new Headers(calls[1].init?.headers).get('X-CSRF-TOKEN')).toBe('before-login');
    expect(new Headers(calls[3].init?.headers).get('X-CSRF-TOKEN')).toBe('after-login');
    expect(calls.every(c => c.init?.credentials === 'include')).toBe(true);
  });
  it('sends expected_revision without writable server fields', async () => {
    const calls: RequestInit[] = [];
    const api = new AdminApi(async (path, init) => {
      if (path.endsWith('/csrf')) return ok({ token: 'token', header_name: 'X-CSRF-TOKEN' });
      calls.push(init!); return ok({});
    });
    await api.save('articles', { ...blankEntity('articles'), id: 'article-id', content_revision: 7, checked_at: 'server-date', content_checked: true, status: 'PUBLISHED' });
    const body = JSON.parse(String(calls[0].body));
    expect(body.expected_revision).toBe(7); expect(body.content_checked).toBe(true);
    for (const key of ['id', 'content_revision', 'status', 'checked_at', 'updated_at']) expect(body).not.toHaveProperty(key);
  });
  it('preserves field errors and never retries a failed write', async () => {
    let writes = 0;
    const api = new AdminApi(async (path) => {
      if (path.endsWith('/csrf')) return ok({ token: 'token', header_name: 'X-CSRF-TOKEN' });
      writes++;
      return new Response(JSON.stringify({ error: { code: 'CONTENT_CONFLICT', message: 'Changed', field_errors: [{ field: 'title', message: 'Conflict' }] } }), { status: 409 });
    });
    await expect(api.publish('article', 1, true)).rejects.toMatchObject({ status: 409, code: 'CONTENT_CONFLICT', fields: [{ field: 'title', message: 'Conflict' }] });
    expect(writes).toBe(1);
  });
  it('signals session expiry, accepts 204, rejects malformed responses and connection failures', async () => {
    const api = new AdminApi(async () => new Response(JSON.stringify({ error: { code: 'AUTH_REQUIRED', message: 'Expired' } }), { status: 401 }));
    api.onUnauthorized = vi.fn(); await expect(api.me()).rejects.toBeInstanceOf(ApiError); expect(api.onUnauthorized).toHaveBeenCalledOnce();
    await expect(new AdminApi(async () => ok(undefined)).me()).rejects.toMatchObject({ code: 'INVALID_RESPONSE' });
    await expect(new AdminApi(async () => { throw new Error('offline'); }).me()).rejects.toMatchObject({ code: 'NETWORK_ERROR' });
  });
  it('loads every page of linked metadata', async () => {
    const api = new AdminApi(async path => { const page = new URL(path, 'http://test').searchParams.get('page'); return ok({ items: [{ id: page }], total: 2, page: Number(page), page_size: 100 }); });
    expect((await api.all('sources')).map(x => x.id)).toEqual(['1', '2']);
  });
});
