import type { Admin, Entities, FieldError, Page, Resource } from './models';

export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string, public fields: FieldError[] = []) { super(message); }
}
export type Transport = (path: string, init?: RequestInit) => Promise<Response>;
export class AdminApi {
  private csrf: { token: string; header_name: string } | null = null;
  onUnauthorized?: () => void;
  constructor(private transport: Transport = (path, init) => fetch(path, init)) {}
  async refreshCsrf() {
    const token = await this.request<{ token: string; header_name: string }>('/auth/csrf');
    if (!token?.token || !/^[-A-Za-z0-9]+$/.test(token.header_name)) throw new ApiError(502, 'INVALID_RESPONSE', 'Không nhận được CSRF token hợp lệ.');
    this.csrf = token;
  }
  private async request<T>(path: string, method = 'GET', body?: unknown): Promise<T> {
    const headers: Record<string, string> = { Accept: 'application/json' };
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    if (method !== 'GET') {
      if (!this.csrf) await this.refreshCsrf();
      headers[this.csrf!.header_name] = this.csrf!.token;
    }
    let response: Response;
    try {
      response = await this.transport(`/api/v1/admin${path}`, { method, headers, credentials: 'include', cache: 'no-store', body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(15000) });
    } catch {
      throw new ApiError(0, 'NETWORK_ERROR', 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại; dữ liệu đang nhập vẫn được giữ.');
    }
    if (response.status === 204 && response.ok) return undefined as T;
    const payload = await response.json().catch(() => null);
    if (!response.ok) {
      if (response.status === 401 && path !== '/auth/login') { this.csrf = null; this.onUnauthorized?.(); }
      if (payload?.error) throw new ApiError(response.status, payload.error.code, payload.error.message, payload.error.field_errors || []);
      throw new ApiError(response.status, 'HTTP_ERROR', 'Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại.');
    }
    if (!payload || !('data' in payload)) throw new ApiError(502, 'INVALID_RESPONSE', 'Dữ liệu máy chủ không đúng định dạng.');
    return payload.data as T;
  }
  me() { return this.request<Admin>('/auth/me'); }
  async login(username: string, password: string) {
    await this.refreshCsrf();
    const user = await this.request<Admin>('/auth/login', 'POST', { username, password });
    await this.refreshCsrf();
    if (user.role !== 'ADMIN') throw new ApiError(403, 'ACCESS_DENIED', 'Tài khoản không có quyền quản trị.');
    return user;
  }
  async logout() { await this.request('/auth/logout', 'POST'); this.csrf = null; }
  list<R extends Resource>(resource: R, filters: Record<string, string | number> = {}) {
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(filters)) if (value !== '') params.set(key, String(value));
    return this.request<Page<Entities[R]>>(`/${resource}?${params}`);
  }
  async all<R extends Resource>(resource: R): Promise<Entities[R][]> {
    const items: Entities[R][] = [];
    let page = 1;
    while (true) {
      const result = await this.list(resource, { page, page_size: 100 });
      items.push(...result.items);
      if (items.length >= result.total) return items;
      if (!result.items.length || page >= 100) throw new ApiError(502, 'INVALID_RESPONSE', 'Danh sách liên kết chưa tải đủ. Vui lòng thử lại.');
      page++;
    }
  }
  get<R extends Resource>(resource: R, id: string) { return this.request<Entities[R]>(`/${resource}/${encodeURIComponent(id)}`); }
  save<R extends Resource>(resource: R, entity: Entities[R]) {
    // Never send server-owned IDs, status, revision counters or timestamps as writable fields.
    const body = { ...entity } as Record<string, unknown>;
    const id = entity.id;
    delete body.id;
    if (resource === 'articles') {
      body.expected_revision = id ? body.content_revision : undefined;
      for (const key of ['status', 'content_revision', 'updated_at', 'checked_at']) delete body[key];
    }
    if (resource === 'sources') delete body.revision;
    return this.request<Entities[R]>(`/${resource}${id ? `/${encodeURIComponent(id)}` : ''}`, id ? 'PUT' : 'POST', body);
  }
  remove(resource: Resource, id: string) { return this.request<void>(`/${resource}/${encodeURIComponent(id)}`, 'DELETE'); }
  publish(id: string, revision: number, publish: boolean) {
    return this.request<Entities['articles']>(`/articles/${encodeURIComponent(id)}/${publish ? 'publish' : 'unpublish'}`, 'POST', { expected_revision: revision });
  }
}
export function errorText(error: unknown): string {
  if (!(error instanceof ApiError)) return 'Có lỗi xảy ra. Vui lòng thử lại.';
  if (error.code === 'CONTENT_CONFLICT') return 'Bài đã được thay đổi ở nơi khác. Bản nhập của bạn vẫn được giữ. Hãy sao chép nội dung cần giữ trước khi tải bản mới; hệ thống không tự ghi đè.';
  if (error.code === 'RESOURCE_IN_USE') return 'Dữ liệu còn được tham chiếu. Hãy xử lý các bài liên quan trước khi xóa hoặc ngừng sử dụng.';
  if (error.code === 'CSRF_INVALID') return 'Phiên bảo vệ đã thay đổi. Bấm “Làm mới phiên” rồi thử lại thao tác; dữ liệu nhập vẫn được giữ.';
  if (error.status === 429) return 'Bạn thao tác quá nhanh. Vui lòng chờ một lúc rồi thử lại.';
  return error.message;
}
