const { randomUUID } = require('node:crypto');

class ApiFailure extends Error {
  constructor(status, code, message, fields = []) {
    super(message);
    Object.assign(this, { status, code, fields });
  }
}
const invalid = (field, message = 'Giá trị không hợp lệ') => new ApiFailure(400, 'VALIDATION_ERROR', 'Dữ liệu chưa hợp lệ', [{ field, message }]);
const notFound = () => new ApiFailure(404, 'NOT_FOUND', 'Không tìm thấy dữ liệu công khai phù hợp');
const inUse = () => new ApiFailure(409, 'RESOURCE_IN_USE', 'Dữ liệu đang được tham chiếu');
const conflict = () => new ApiFailure(409, 'CONTENT_CONFLICT', 'Bài đã được sửa ở nơi khác');
const unavailable = () => new ApiFailure(503, 'SERVICE_UNAVAILABLE', 'Dịch vụ tạm thời không sẵn sàng');
const ok = data => ({ data, meta: { trace_id: randomUUID() } });
const isObject = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const checks = {
  text(b, key, max, required = false) {
    const v = b[key];
    if (v == null && !required) return null;
    if (typeof v !== 'string' || v.trim().length > max || (required && !v.trim())) throw invalid(key, 'Độ dài hoặc kiểu dữ liệu không hợp lệ');
    return v.trim() || null;
  },
  value(b, key, allowed) {
    const v = this.text(b, key, 80, true);
    if (!allowed.includes(v)) throw invalid(key);
    return v;
  },
  uuid(b, key) {
    const v = this.text(b, key, 36, true);
    if (!uuidPattern.test(v)) throw invalid(key, 'UUID không hợp lệ');
    return v.toLowerCase();
  },
  bool(b, key, fallback = false) {
    if (b[key] == null) return fallback;
    if (typeof b[key] !== 'boolean') throw invalid(key, 'Cần true hoặc false');
    return b[key];
  },
  integer(b, key, min, max, fallback = null) {
    if (b[key] == null) return fallback;
    if (!Number.isSafeInteger(b[key]) || b[key] < min || b[key] > max) throw invalid(key, 'Số nguyên ngoài giới hạn');
    return b[key];
  },
  strings(b, key, max) {
    const v = b[key];
    if (!Array.isArray(v) || v.length > max || v.some(s => typeof s !== 'string' || !s.trim() || s.length > 4000)) throw invalid(key, 'Cần mảng chuỗi hợp lệ');
    return v.map(s => s.trim());
  },
  objects(b, key, max) {
    const v = b[key];
    if (!Array.isArray(v) || v.length > max || v.some(s => !isObject(s))) throw invalid(key, 'Cần mảng đối tượng hợp lệ');
    return v;
  },
  https(v, key) {
    if (v === null) return null;
    try { const u = new URL(v); if (u.protocol === 'https:' && u.hostname) return v; } catch {}
    throw invalid(key, 'Cần URL HTTPS hợp lệ');
  },
  revision(b) {
    const v = this.integer(b, 'expected_revision', 1, Number.MAX_SAFE_INTEGER);
    if (v === null) throw invalid('expected_revision', 'Cần revision hợp lệ');
    return v;
  },
};

function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);
  let failure = err;
  if (!(err instanceof ApiFailure)) {
    if (err.code === 'LIMIT_FILE_SIZE') failure = new ApiFailure(413, 'IMAGE_TOO_LARGE', 'Ảnh vượt giới hạn 5 MB');
    else if (err.name === 'MulterError' || err.type === 'entity.parse.failed' || err.type === 'entity.too.large') failure = invalid('request');
    else if (/^23/.test(err.code || '')) failure = inUse();
    else if (['40001', '40P01'].includes(err.code)) failure = conflict();
    else failure = unavailable();
  }
  if (failure.status === 429) res.set('Retry-After', '60');
  res.status(failure.status).json({ error: { code: failure.code, message: failure.message, field_errors: failure.fields }, meta: { trace_id: randomUUID() } });
}

// Bounded, process-local quota, as in the previous backend. No raw messages are stored.
class Limiter {
  constructor(max, windowMs) { this.max = max; this.windowMs = windowMs; this.windows = new Map(); this.count = 0; }
  check(key) {
    const now = Date.now();
    const times = (this.windows.get(key) || []).filter(t => t > now - this.windowMs);
    if (times.length >= this.max) throw new ApiFailure(429, 'RATE_LIMITED', 'Vui lòng thử lại sau');
    times.push(now); this.windows.set(key, times);
    if (++this.count % 100 === 0) for (const [ip, entries] of this.windows) if (entries.at(-1) <= now - this.windowMs) this.windows.delete(ip);
  }
}

function concurrencyLimit(max, handler) {
  let active = 0;
  return async (req, res) => {
    if (active >= max) throw new ApiFailure(429, 'RATE_LIMITED', 'Vui lòng thử lại sau');
    active++;
    // Hold the slot until work finishes, even if the client closes its connection.
    try { await handler(req, res); } finally { active--; }
  };
}
module.exports = { ApiFailure, invalid, notFound, inUse, conflict, unavailable, ok, checks, isObject, uuidPattern, errorHandler, Limiter, concurrencyLimit };
