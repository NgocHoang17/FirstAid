import type { Article, Category, Entities, FieldError, Resource, Source } from './models';
const https = (value: string) => { try { return new URL(value).protocol === 'https:'; } catch { return false; } };
export function validate<R extends Resource>(resource: R, entity: Entities[R], categories: Category[] = [], sources: Source[] = [], publishing = false): FieldError[] {
  const errors: FieldError[] = [];
  const add = (field: string, message: string) => errors.push({ field, message });
  const required = (field: string, value: string) => { if (!value.trim()) add(field, 'Không được để trống.'); };
  if (resource === 'articles') {
    const a = entity as Article;
    required('title', a.title); required('category_id', a.category_id); required('slug', a.slug); required('variant_key', a.variant_key);
    if (!/^[a-z0-9]+(?:[-_][a-z0-9]+)*$/.test(a.slug)) add('slug', 'Dùng chữ thường không dấu, số, dấu gạch ngang hoặc gạch dưới.');
    if (!/^[a-z0-9_]+$/.test(a.variant_key)) add('variant_key', 'Dùng chữ thường không dấu, số và dấu gạch dưới.');
    a.steps.forEach((s, i) => {
      required(`steps.${i}.title`, s.title); required(`steps.${i}.instruction`, s.instruction);
      if (s.position !== i + 1) add(`steps.${i}.position`, 'Thứ tự bước phải liên tiếp từ 1.');
      if (s.image_url && !https(s.image_url)) add(`steps.${i}.image_url`, 'Ảnh bổ sung phải dùng URL HTTPS.');
      if ((s.image_url || s.asset_key) && !s.alt_text?.trim()) add(`steps.${i}.alt_text`, 'Cần mô tả hình cho người đọc màn hình.');
    });
    a.references.forEach((r, i) => {
      const source = sources.find(s => s.id === r.source_id);
      if (!source) add(`references.${i}.source_id`, 'Chọn nguồn tài liệu tồn tại.');
      else if (source.media_type === 'WEB') {
        if (r.page_start !== null || r.page_end !== null) add(`references.${i}.page_start`, 'Nguồn web không có số trang PDF.');
      } else if (!Number.isInteger(r.page_start) || !Number.isInteger(r.page_end) || r.page_start! < 1 || r.page_end! < r.page_start! || r.page_end! > (source.page_count ?? 0)) add(`references.${i}.page_start`, 'Trang trích phải nằm trong số trang PDF và trang cuối không nhỏ hơn trang đầu.');
      if (publishing && source && !source.is_active) add(`references.${i}.source_id`, 'Nguồn đã ngừng sử dụng.');
    });
    if (publishing) {
      for (const key of ['applies_to', 'summary'] as const) required(key, a[key]);
      for (const key of ['recognition', 'quick_actions', 'warnings', 'seek_help'] as const) if (!a[key].length || a[key].some(x => !x.trim())) add(key, 'Cần nội dung đã được kiểm tra; không thêm lời khuyên giả để đủ trường.');
      if (!a.steps.length) add('steps', 'Cần ít nhất một bước hướng dẫn.');
      if (!a.references.length) add('references', 'Cần ít nhất một nguồn tham chiếu.');
      if (!categories.find(c => c.id === a.category_id)?.is_active) add('category_id', 'Danh mục phải đang sử dụng.');
      if (!a.content_checked || !a.checked_at) add('content_checked', 'Lưu xác nhận đã đối chiếu nội dung trước khi xuất bản.');
    }
  } else if (resource === 'categories') {
    const c = entity as Entities['categories']; required('name', c.name);
    if (!/^FA(0[1-9]|1[0-8])$/.test(c.code)) add('code', 'Mã danh mục trong phạm vi FA01–FA18.');
    if (!Number.isInteger(c.sort_order) || c.sort_order < 1) add('sort_order', 'Nhập số nguyên dương.');
  } else if (resource === 'sources') {
    const s = entity as Source; required('code', s.code); required('title', s.title); required('publisher', s.publisher);
    if (s.publication_year !== null && (!Number.isInteger(s.publication_year) || s.publication_year < 1 || s.publication_year > new Date().getFullYear())) add('publication_year', 'Năm xuất bản phải hợp lệ; chưa rõ thì để trống.');
    if (s.original_url && !https(s.original_url)) add('original_url', 'Chỉ nhận URL HTTPS.');
    if (s.media_type === 'WEB' && (!s.original_url || s.page_count !== null)) add('original_url', 'Nguồn web cần URL HTTPS và không có số trang.');
    if (s.media_type === 'PDF' && (!Number.isInteger(s.page_count) || s.page_count! < 1)) add('page_count', 'PDF cần số trang nguyên dương.');
  } else {
    const f = entity as Entities['facilities']; required('name', f.name); required('address', f.address); required('region_code', f.region_code);
    if ((f.latitude === null) !== (f.longitude === null)) add('latitude', 'Nhập đủ cả vĩ độ và kinh độ, hoặc để trống cả hai.');
    if (f.latitude !== null && (!Number.isFinite(f.latitude) || Math.abs(f.latitude) > 90)) add('latitude', 'Vĩ độ từ -90 đến 90.');
    if (f.longitude !== null && (!Number.isFinite(f.longitude) || Math.abs(f.longitude) > 180)) add('longitude', 'Kinh độ từ -180 đến 180.');
    if (f.phone && (!/^\+?[\d ()-]{7,25}$/.test(f.phone) || f.phone.replace(/\D/g, '') === '115')) add('phone', 'Nhập số điện thoại riêng của cơ sở đã xác minh, không dùng 115.');
    if (f.verified_at && (!Number.isFinite(Date.parse(f.verified_at)) || Date.parse(f.verified_at) > Date.now())) add('verified_at', 'Ngày xác minh phải hợp lệ và không ở tương lai.');
    if (f.is_active) {
      if (!f.phone) add('phone', 'Cần điện thoại đã được xác minh.');
      if (f.latitude === null || f.longitude === null) add('latitude', 'Cơ sở đang sử dụng cần tọa độ.');
      required('verification_note', f.verification_note);
      if (!f.verified_at) add('verified_at', 'Cần ngày xác minh trước khi sử dụng.');
    }
  }
  return errors;
}
