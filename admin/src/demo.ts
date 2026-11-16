// Development-only adapter. Production builds eliminate this module and its fixture import.
import library from '../../mobile/assets/content/reference_library.json';
import { ApiError, type Transport } from './api';
import { normalize, type Article, type Category, type Entities, type Resource, type Source } from './models';
import { validate } from './validation';

export function createDemoTransport(): Transport {
  const db: { [K in Resource]: Entities[K][] } = {
    articles: structuredClone(library.articles) as Article[],
    categories: structuredClone(library.categories) as Category[],
    sources: structuredClone(library.sources) as Source[], facilities: [],
  };
  let loggedIn = false;
  let token = crypto.randomUUID();
  const admin = { id: '65a704ba-8452-40cd-82e6-6e3b054b1322', username: 'demo', role: 'ADMIN' };
  const response = (data: unknown, status = 200) => new Response(status === 204 ? null : JSON.stringify({ data }), { status, headers: { 'Content-Type': 'application/json' } });
  return async (path, init) => {
    await new Promise(resolve => setTimeout(resolve, 120));
    try {
      const url = new URL(path, 'http://localhost');
      const segments = url.pathname.replace('/api/v1/admin/', '').split('/');
      const [resource, id, action] = segments;
      const method = init?.method || 'GET';
      const body = init?.body ? JSON.parse(String(init.body)) : {};
      const headers = new Headers(init?.headers);
      if (method !== 'GET' && headers.get('X-CSRF-TOKEN') !== token) throw new ApiError(403, 'CSRF_INVALID', 'CSRF token không hợp lệ.');
      if (resource === 'auth') {
        if (id === 'csrf') return response({ token, header_name: 'X-CSRF-TOKEN' });
        if (id === 'login') {
          if (body.username !== 'demo' || body.password !== 'demo') throw new ApiError(401, 'INVALID_CREDENTIALS', 'Tài khoản demo chưa đúng.');
          loggedIn = true; token = crypto.randomUUID(); return response(admin);
        }
        if (!loggedIn) throw new ApiError(401, 'AUTH_REQUIRED', 'Vui lòng đăng nhập.');
        if (id === 'me') return response(admin);
        if (id === 'logout') { loggedIn = false; token = crypto.randomUUID(); return response(null, 204); }
      }
      if (!loggedIn) throw new ApiError(401, 'AUTH_REQUIRED', 'Vui lòng đăng nhập.');
      if (!(resource in db)) throw new ApiError(404, 'NOT_FOUND', 'Không tìm thấy.');
      const key = resource as Resource;
      // Keep the heterogeneous fixture store behind the same JSON boundary as HTTP.
      const rows = db[key] as unknown as Record<string, unknown>[];
      const existing = rows.find(row => row.id === id);
      if (id && !existing) throw new ApiError(404, 'NOT_FOUND', 'Dữ liệu đã bị xóa.');
      if (method === 'GET') {
        if (id) return response(existing);
        const q = normalize(url.searchParams.get('q') || '');
        const filtered = rows.filter(row => normalize(`${row.title || row.name} ${row.code || ''}`).includes(q) && ['status', 'category_id', 'region_code'].every(field => !url.searchParams.get(field) || row[field] === url.searchParams.get(field)));
        const page = Math.max(1, Number(url.searchParams.get('page') || 1));
        const pageSize = Math.min(100, Math.max(1, Number(url.searchParams.get('page_size') || 20)));
        return response({ items: filtered.slice((page - 1) * pageSize, page * pageSize), total: filtered.length, page, page_size: pageSize });
      }
      if (key === 'articles' && existing && method !== 'DELETE' && body.expected_revision !== existing.content_revision) throw new ApiError(409, 'CONTENT_CONFLICT', 'Revision đã thay đổi.');
      const inUse = () => db.articles.some(a => key === 'categories' ? a.category_id === id : key === 'sources' && a.references.some(r => r.source_id === id) && (method === 'DELETE' || a.status === 'PUBLISHED'));
      if (method === 'DELETE') {
        if (inUse()) throw new ApiError(409, 'RESOURCE_IN_USE', 'Dữ liệu đang được tham chiếu.');
        rows.splice(rows.indexOf(existing!), 1); return response(null, 204);
      }
      if (action === 'publish' || action === 'unpublish') {
        if (action === 'publish') {
          const errors = validate('articles', existing as unknown as Article, db.categories, db.sources, true);
          if (errors.length) throw new ApiError(422, 'CONTENT_NOT_READY', 'Bài chưa đủ điều kiện xuất bản.', errors);
        }
        Object.assign(existing!, { status: action === 'publish' ? 'PUBLISHED' : 'DRAFT', content_revision: Number(existing!.content_revision) + 1, updated_at: new Date().toISOString() });
        return response(existing);
      }
      const value = { ...body, id: id || crypto.randomUUID() };
      delete value.expected_revision;
      if (key === 'articles') {
        value.status = 'DRAFT'; value.content_revision = Number(existing?.content_revision || 0) + 1; value.updated_at = new Date().toISOString();
        // Editing a public article always clears its previous confirmation.
        value.content_checked = existing?.status === 'PUBLISHED' ? false : Boolean(body.content_checked);
        value.checked_at = value.content_checked ? new Date().toISOString() : null;
        value.steps = value.steps.map((step: Record<string, unknown>, i: number) => ({ ...step, id: step.id || crypto.randomUUID(), position: i + 1 }));
      }
      if (key === 'sources') value.revision = Number(existing?.revision || 0) + 1;
      const errors = validate(key, value as unknown as Entities[Resource], db.categories, db.sources);
      if (errors.length) throw new ApiError(400, 'VALIDATION_ERROR', 'Kiểm tra lại các trường được đánh dấu.', errors);
      if (existing && body.is_active === false && inUse() && (key === 'sources' || db.articles.some(a => a.category_id === id && a.status === 'PUBLISHED'))) throw new ApiError(409, 'RESOURCE_IN_USE', 'Còn bài đã xuất bản đang tham chiếu.');
      const unique = key === 'articles' ? rows.some(r => r.id !== id && (r.slug === value.slug || (r.category_id === value.category_id && r.variant_key === value.variant_key))) : (key === 'categories' || key === 'sources') && rows.some(r => r.id !== id && r.code === value.code);
      if (unique) throw new ApiError(400, 'VALIDATION_ERROR', 'Mã hoặc đường dẫn đã tồn tại.', [{ field: key === 'articles' ? 'slug' : 'code', message: 'Giá trị đã được sử dụng.' }]);
      if (existing) rows.splice(rows.indexOf(existing), 1, value); else rows.push(value);
      return response(value, existing ? 200 : 201);
    } catch (error) {
      if (!(error instanceof ApiError)) throw error;
      return new Response(JSON.stringify({ error: { code: error.code, message: error.message, field_errors: error.fields } }), { status: error.status });
    }
  };
}
