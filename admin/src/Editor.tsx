import { useEffect, useState } from 'react';
import { ArrowLeft, Check, Eye, Save, Send, Undo2 } from 'lucide-react';
import { AdminApi } from './api';
import { ArticleFields } from './ArticleFields';
import { ArticlePreview } from './ArticlePreview';
import { EntityFields } from './EntityFields';
import { Busy, Errors, StatusBadge, type Confirmation } from './components';
import { blankEntity, resourceLabels, type Article, type Category, type Entity, type FieldError, type Resource, type Source } from './models';
import { validate } from './validation';

export function Editor({ api, resource, id, back, confirm, setDirty, notify }: { api: AdminApi; resource: Resource; id: string; back: () => void; confirm: (value: Confirmation) => void; setDirty: (dirty: boolean) => void; notify: (text: string) => void }) {
  const [value, setValue] = useState<Entity | null>(null);
  const [original, setOriginal] = useState<Entity | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [sources, setSources] = useState<Source[]>([]);
  const [error, setError] = useState<unknown>();
  const [fields, setFields] = useState<FieldError[]>([]);
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(true);
  const [preview, setPreview] = useState(true);
  const [reload, setReload] = useState(0);
  const [dirty, markDirty] = useState(false);
  useEffect(() => {
    let active = true;
    setLoading(true); setError(undefined); setFields([]);
    Promise.all([id === 'new' ? Promise.resolve(blankEntity(resource)) : api.get(resource, id), resource === 'articles' ? api.all('categories') : Promise.resolve([]), resource === 'articles' ? api.all('sources') : Promise.resolve([])])
      .then(([entity, cats, refs]) => { if (active) { setValue(entity); setOriginal(structuredClone(entity)); setCategories(cats); setSources(refs); setDirty(false); markDirty(false); } })
      .catch(e => { if (active) setError(e); }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [api, resource, id, reload, setDirty]);
  const change = (next: Entity) => {
    if (resource === 'articles' && (value as Article).content_checked === (next as Article).content_checked) {
      next = { ...next, content_checked: false, checked_at: null } as Article;
    }
    setValue(next); setDirty(true); markDirty(true);
  };
  const fresh = () => confirm({ title: 'Tải bản mới từ máy chủ?', description: 'Bản đang nhập sẽ bị thay thế. Hãy sao chép nội dung cần giữ trước khi tiếp tục.', confirmLabel: 'Tải bản mới', action: () => setReload(n => n + 1) });
  const save = async () => {
    if (!value) return;
    const next = structuredClone(value);
    if (resource === 'articles') {
      const a = next as Article;
      for (const key of ['recognition', 'quick_actions', 'warnings', 'seek_help'] as const) a[key] = a[key].map(x => x.trim()).filter(Boolean);
      a.steps = a.steps.map((s, i) => ({ ...s, position: i + 1 }));
    }
    if (resource === 'categories') (next as Category).keywords = (next as Category).keywords.map(x => x.trim()).filter(Boolean);
    const validation = validate(resource, next, categories, sources);
    setFields(validation); setError(undefined);
    if (validation.length) return;
    setBusy(true);
    try { const saved = await api.save(resource, next); setValue(saved); setOriginal(structuredClone(saved)); setDirty(false); markDirty(false); notify('Đã lưu thay đổi.'); }
    catch (e) { setError(e); } finally { setBusy(false); }
  };
  const requestSave = () => {
    if (resource === 'articles' && (original as Article)?.status === 'PUBLISHED') confirm({ title: 'Lưu bài và chuyển về nháp?', description: 'Bài sẽ rời dữ liệu công khai khi lưu. Xác nhận nội dung cũ sẽ bị xóa; cần kiểm tra, lưu xác nhận và xuất bản lại.', confirmLabel: 'Lưu và chuyển về nháp', action: save });
    else void save();
  };
  const publication = () => {
    const a = value as Article;
    if (dirty) { setError(undefined); setFields([{ field: 'title', message: 'Lưu các thay đổi trước khi xuất bản hoặc gỡ xuất bản.' }]); return; }
    const publish = a.status !== 'PUBLISHED';
    const validation = publish ? validate('articles', a, categories, sources, true) : [];
    setFields(validation); setError(undefined); if (validation.length) return;
    confirm({ title: publish ? 'Xuất bản bài sơ cứu?' : 'Gỡ xuất bản bài sơ cứu?', description: publish ? 'Bài đã lưu sẽ xuất hiện trong dữ liệu công khai ở lần cập nhật tiếp theo.' : 'Bài sẽ chuyển về nháp và rời dữ liệu công khai ở lần cập nhật tiếp theo.', confirmLabel: publish ? 'Xuất bản bài' : 'Gỡ xuất bản', danger: !publish, action: async () => {
      setBusy(true);
      try { const saved = await api.publish(a.id, a.content_revision, publish); setValue(saved); setOriginal(structuredClone(saved)); notify(publish ? 'Đã xuất bản bài.' : 'Đã gỡ xuất bản bài.'); }
      catch (e) { setError(e); } finally { setBusy(false); }
    } });
  };
  if (loading) return <Busy/>;
  if (!value) return <><Errors error={error}/><button onClick={() => setReload(n => n + 1)}>Thử tải lại</button><button onClick={back}>Quay lại</button></>;
  const isArticle = resource === 'articles';
  return <><div className="editor-heading"><div><button className="back-button" onClick={back}><ArrowLeft size={17}/>Danh sách {resourceLabels[resource].toLowerCase()}</button><div className="title-row"><h1>{value.id ? 'Biên tập' : 'Tạo mới'} {resourceLabels[resource].toLowerCase()}</h1>{isArticle && <StatusBadge published={(value as Article).status === 'PUBLISHED'}/>}</div><p className="muted">{dirty ? 'Có thay đổi chưa lưu' : <><Check size={14}/> {value.id ? 'Đã lưu' : 'Chưa tạo dữ liệu'}{isArticle && value.id ? ` · Revision ${(value as Article).content_revision}` : ''}</>}</p></div></div>
    <Errors error={error} fields={fields} refresh={() => { void api.refreshCsrf().then(() => { setError(undefined); notify('Đã làm mới phiên. Có thể thử lại thao tác.'); }).catch(setError); }} reload={fresh}/>
    <form onSubmit={e => { e.preventDefault(); requestSave(); }}><fieldset disabled={busy} className="editor-fieldset"><div className={`editor-layout ${preview && isArticle ? 'with-preview' : ''}`}>{isArticle ? <ArticleFields article={value as Article} categories={categories} sources={sources} change={change}/> : <EntityFields resource={resource} value={value} change={change}/>} {preview && isArticle && <ArticlePreview article={value as Article} sources={sources}/>}</div>
    <div className="editor-actions"><span>{busy ? 'Đang xử lý…' : dirty ? 'Thay đổi chưa được lưu' : 'Nội dung đã sẵn sàng để biên tập'}</span><div className="actions">{isArticle && <button type="button" aria-pressed={preview} onClick={() => setPreview(!preview)}><Eye size={17}/>{preview ? 'Ẩn xem trước' : 'Xem trước'}</button>}<button type="button" onClick={back}><Undo2 size={17}/>Quay lại</button><button type="submit" className="primary"><Save size={17}/>{isArticle ? 'Lưu bản nháp' : 'Lưu thay đổi'}</button>{isArticle && value.id && <button type="button" className={(value as Article).status === 'PUBLISHED' ? '' : 'publish-button'} onClick={publication}><Send size={17}/>{(value as Article).status === 'PUBLISHED' ? 'Gỡ xuất bản' : 'Xuất bản'}</button>}</div></div></fieldset></form></>;
}
