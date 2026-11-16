import { Field } from './components';
import { nullable, type Category, type Entity, type Facility, type Resource, type Source } from './models';

export function EntityFields({ resource, value, change }: { resource: Exclude<Resource, 'articles'>; value: Entity; change: (value: Entity) => void }) {
  const set = (key: string, next: unknown) => change({ ...value, [key]: next });
  const text = (key: string, label: string, content: string | null, required = false, hint?: string) => <Field label={label} required={required} hint={hint}><input id={`field-${key}`} value={content || ''} onChange={e => set(key, e.target.value)} /></Field>;
  const paragraph = (key: string, label: string, content: string) => <Field label={label}><textarea id={`field-${key}`} rows={3} value={content} onChange={e => set(key, e.target.value)}/></Field>;
  const number = (key: string, label: string, content: number | null, required = false) => <Field label={label} required={required}><input id={`field-${key}`} type="number" step="any" value={content ?? ''} onChange={e => set(key, e.target.value === '' ? null : Number(e.target.value))}/></Field>;
  return <div className="panel form-panel"><div className="form-grid">{resource === 'categories' ? (() => { const c = value as Category; return <>
    <Field label="Mã danh mục" required hint={c.id ? 'Mã ổn định dùng chung với mobile và AI.' : 'Mã trong phạm vi FA01–FA18.'}><input id="field-code" readOnly={Boolean(c.id)} value={c.code} onChange={e => set('code', e.target.value)}/></Field>
    {text('name', 'Tên danh mục', c.name, true)}
    <Field label="Nhóm"><select value={c.group_code} onChange={e => set('group_code', e.target.value)}><option value="CIRCULATION">Tuần hoàn & hô hấp</option><option value="TRAUMA">Chấn thương</option><option value="ENVIRONMENT">Môi trường</option><option value="OTHER">Khác</option></select></Field>
    {number('sort_order', 'Thứ tự hiển thị', c.sort_order, true)}
    <div className="full">{paragraph('description', 'Mô tả', c.description)}</div>
    <div className="full"><Field label="Từ khóa" hint="Mỗi dòng một từ khóa hoặc cách gọi thường gặp."><textarea value={c.keywords.join('\n')} rows={4} onChange={e => set('keywords', e.target.value.split('\n'))}/></Field></div>
  </>; })() : resource === 'sources' ? (() => { const s = value as Source; return <>
    {text('code', 'Mã nguồn', s.code, true)}
    <Field label="Loại tài liệu"><select value={s.media_type} onChange={e => change({ ...s, media_type: e.target.value as Source['media_type'], page_count: null })}><option value="PDF">PDF</option><option value="WEB">Trang web chính thức</option></select></Field>
    <div className="full">{text('title', 'Tên tài liệu', s.title, true)}</div>
    <div className="full">{text('publisher', 'Đơn vị biên soạn / xuất bản', s.publisher, true)}</div>
    {number('publication_year', 'Năm xuất bản', s.publication_year)}
    {s.media_type === 'PDF' && number('page_count', 'Số trang PDF', s.page_count, true)}
    <div className="full"><Field label="URL gốc" hint="HTTPS. Không biết năm thì để trống, không suy từ ngày truy cập."><input id="field-original_url" value={s.original_url || ''} onChange={e => set('original_url', nullable(e.target.value))}/></Field></div>
    <div className="full">{paragraph('rights_note', 'Ghi chú quyền sử dụng', s.rights_note)}</div>
    <p className="full muted">Chỉ quản lý metadata nguồn. Revision do máy chủ quản lý; không tải lên hoặc huấn luyện AI từ màn hình này.</p>
  </>; })() : (() => { const f = value as Facility; return <>
    <div className="full">{text('name', 'Tên cơ sở', f.name, true)}</div>
    {text('region_code', 'Mã vùng', f.region_code, true)}
    <Field label="Số điện thoại riêng" hint="Không dùng số cấp cứu 115 làm số của cơ sở."><input id="field-phone" type="tel" value={f.phone || ''} onChange={e => set('phone', nullable(e.target.value))}/></Field>
    <div className="full">{text('address', 'Địa chỉ', f.address, true)}</div>
    {number('latitude', 'Vĩ độ', f.latitude)}{number('longitude', 'Kinh độ', f.longitude)}
    <Field label="Cấp cứu 24/7"><select value={f.emergency_24h} onChange={e => set('emergency_24h', e.target.value)}><option value="UNKNOWN">Chưa xác minh</option><option value="YES">Có</option><option value="NO">Không</option></select></Field>
    <Field label="Ngày xác minh"><input id="field-verified_at" type="date" max={new Date().toISOString().slice(0, 10)} value={f.verified_at?.slice(0, 10) || ''} onChange={e => set('verified_at', e.target.value ? `${e.target.value}T00:00:00Z` : null)}/></Field>
    <div className="full">{paragraph('verification_note', 'Nguồn và ghi chú xác minh', f.verification_note)}</div>
    <p className="full muted">Chỉ bật sử dụng sau khi kiểm tra thông tin thực tế. Chọn “Chưa xác minh” nếu chưa rõ khả năng cấp cứu 24/7.</p>
  </>; })()}
  <label className="checkbox full"><input type="checkbox" checked={(value as Category | Source | Facility).is_active} onChange={e => set('is_active', e.target.checked)}/><span>Đang sử dụng</span></label></div></div>;
}
