const { checks: C, invalid, ApiFailure } = require('./api');

function pageParams(q) {
  const parse = (key, fallback, max) => {
    const raw = q[key];
    if (raw == null) return fallback;
    if (typeof raw !== 'string' || !/^\d+$/.test(raw)) throw invalid('page');
    return C.integer({ [key]: Number(raw) }, key, 1, max);
  };
  return { page: parse('page', 1, 100000), size: parse('page_size', 20, 100) };
}

function filters(q) {
  return { category: q.category_id == null ? null : C.uuid(q, 'category_id'), age: q.age_group == null ? null : C.value(q, 'age_group', ['ADULT', 'CHILD', 'ALL']), q: C.text(q, 'q', 2000), status: q.status == null ? null : C.value(q, 'status', ['DRAFT', 'PUBLISHED']) };
}

function bounded(items, max) {
  if (items.length > max) throw new ApiFailure(503, 'SERVICE_UNAVAILABLE', 'Tập dữ liệu vượt giới hạn contract');
  return { items };
}

module.exports = { pageParams, filters, bounded };
