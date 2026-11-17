import { useRef, useState } from 'react';
import type { AdminApi } from './api';
import { errorText } from './api';
import type { Step, StepImage } from './models';
import { Field } from './components';

export function StepGallery({ step }: { step: Step }) {
  if (!step.images?.length) return null;
  return <div className={`step-gallery layout-${step.image_layout || 'stacked'}`} aria-label="Ảnh hướng dẫn">
    {step.images.map(image => <figure key={image.media_id}><img src={image.url} alt={image.alt_text}/>{image.caption && <figcaption>{image.caption}</figcaption>}</figure>)}
  </div>;
}

export function StepMediaEditor({ step, change, api, onBusy }: { step: Step; change: (step: Step) => void; api?: AdminApi; onBusy?: (busy: boolean) => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const input = useRef<HTMLInputElement>(null);
  const images = step.images || [];
  async function upload(files: File[]) {
    if (!api || !files.length || busy) return;
    if (files.length + images.length > 6) { setError('Mỗi bước tối đa 6 ảnh.'); return; }
    if (files.some(f => !['image/jpeg','image/png'].includes(f.type) || f.size > 5 * 1024 * 1024)) {
      setError('Chọn JPEG hoặc PNG, tối đa 5 MB mỗi ảnh.'); return;
    }
    change({ ...step });
    setBusy(true); onBusy?.(true); setError('');
    const uploaded: StepImage[] = [];
    try {
      for (const file of files) {
        const media = await api.uploadImage(file);
        uploaded.push({ media_id: media.id, url: media.url, alt_text: '', caption: '' });
      }
    } catch (error) { setError(errorText(error)); }
    finally {
      if (uploaded.length) change({ ...step, images: [...images, ...uploaded], image_layout: step.image_layout || 'stacked' });
      setBusy(false); onBusy?.(false);
      if (input.current) input.current.value = '';
    }
  }
  const update = (index: number, values: Partial<StepImage>) => change({ ...step, images: images.map((image, n) => n === index ? { ...image, ...values } : image) });
  return <section className="media-editor" aria-label="Ảnh tải lên">
    <h3>Ảnh hướng dẫn</h3><p>Thêm ảnh cho bước nếu cần. Tối đa 6 ảnh JPEG/PNG, 5 MB mỗi ảnh. Chỉ sử dụng ảnh có quyền chia sẻ.</p>
    <Field label="Tải ảnh hướng dẫn"><input className="sr-only" ref={input} type="file" accept="image/png,image/jpeg" multiple disabled={busy || !api} onChange={e => void upload(Array.from(e.target.files || []))}/></Field>
    <button type="button" disabled={busy || !api} onClick={() => input.current?.click()}>Chọn ảnh từ máy</button>
    {busy && <p role="status">Đang tải và xử lý ảnh…</p>}
    {error && <p role="alert" className="media-error">{error}</p>}
    {images.length > 0 && <>
      <Field label="Bố cục ảnh"><select value={step.image_layout || 'stacked'} onChange={e => change({ ...step, image_layout: e.target.value as Step['image_layout'] })}>
        <option value="stacked">Xếp dọc</option><option value="grid">Lưới hai cột</option><option value="carousel">Vuốt ngang</option>
      </select></Field>
      {images.map((image, index) => <div className="media-item" key={image.media_id}>
        <img src={image.url} alt={image.alt_text || `Ảnh đang biên tập ${index + 1}`}/>
        <div className="media-details">
          <Field label={`Mô tả ảnh ${index + 1}`} required hint="Mô tả nội dung để người dùng đọc màn hình hiểu được ảnh."><input value={image.alt_text} onChange={e => update(index, { alt_text: e.target.value })}/></Field>
          <Field label={`Chú thích ảnh ${index + 1}`}><textarea rows={2} value={image.caption} onChange={e => update(index, { caption: e.target.value })}/></Field>
          <div className="actions"><button type="button" disabled={index === 0} onClick={() => { const next=[...images]; [next[index-1],next[index]]=[next[index],next[index-1]]; change({...step,images:next}); }}>Lên</button>
            <button type="button" disabled={index === images.length-1} onClick={() => { const next=[...images]; [next[index+1],next[index]]=[next[index],next[index+1]]; change({...step,images:next}); }}>Xuống</button>
            <button type="button" onClick={() => change({...step,images:images.filter((_,n)=>n!==index)})}>Bỏ ảnh {index+1}</button></div>
        </div>
      </div>)}
      <StepGallery step={step}/>
    </>}
  </section>;
}
