import { cloneElement, isValidElement, useEffect, useId, useRef, type ReactElement, type ReactNode } from 'react';
import { AlertCircle, Check, LoaderCircle, X } from 'lucide-react';
import { ApiError, errorText } from './api';
import type { FieldError } from './models';

export function Field({ label, children, hint, required = false }: { label: string; children: ReactNode; hint?: string; required?: boolean }) {
  const generated = useId();
  const control = children as ReactElement<{ id?: string; 'aria-describedby'?: string; 'aria-required'?: boolean }>;
  const id = control.props?.id || generated;
  return <div className="field"><label htmlFor={id} className={required ? 'required-label' : undefined}>{label}</label>{isValidElement(control) ? cloneElement(control, { id, 'aria-describedby': hint ? `${id}-hint` : undefined, 'aria-required': required || undefined }) : children}{hint && <small id={`${id}-hint`}>{hint}</small>}</div>;
}
export function Notice({ children, kind = 'info' }: { children: ReactNode; kind?: 'info' | 'error' | 'success' }) {
  return <div className={`notice ${kind}`} role={kind === 'error' ? 'alert' : 'status'}>{kind === 'success' ? <Check size={19}/> : <AlertCircle size={19}/>}<div>{children}</div></div>;
}
export function Errors({ error, fields, refresh, reload }: { error?: unknown; fields?: FieldError[]; refresh?: () => void; reload?: () => void }) {
  const ref = useRef<HTMLDivElement>(null);
  const items = fields?.length ? fields : error instanceof ApiError ? error.fields : [];
  useEffect(() => { if (error || items.length) ref.current?.focus(); }, [error, items.length]);
  if (!error && !items.length) return null;
  return <div ref={ref} tabIndex={-1} className="error-summary"><Notice kind="error"><strong>{error ? errorText(error) : 'Kiểm tra lại các trường sau.'}</strong>{items.length > 0 && <ul>{items.map((f, i) => <li key={i}><a href={`#field-${f.field}`} onClick={e => { e.preventDefault(); document.getElementById(`field-${f.field}`)?.focus(); }}>{f.field}: {f.message}</a></li>)}</ul>}{error instanceof ApiError && error.code === 'CSRF_INVALID' && refresh && <button type="button" onClick={refresh}>Làm mới phiên</button>}{error instanceof ApiError && error.code === 'CONTENT_CONFLICT' && reload && <button type="button" onClick={reload}>Tải bản mới</button>}</Notice></div>;
}
export function Busy({ text = 'Đang tải dữ liệu…' }: { text?: string }) { return <div className="busy" role="status"><LoaderCircle className="spin" size={24}/>{text}</div>; }
export function StatusBadge({ published }: { published: boolean }) { return <span className={`badge ${published ? 'published' : 'draft'}`}><span/>{published ? 'Đã xuất bản' : 'Bản nháp'}</span>; }

export interface Confirmation { title: string; description: string; confirmLabel: string; danger?: boolean; action: () => void | Promise<void> }
export function ConfirmDialog({ value, close }: { value: Confirmation | null; close: () => void }) {
  const dialog = useRef<HTMLDialogElement>(null);
  const cancel = useRef<HTMLButtonElement>(null);
  const title = useId();
  useEffect(() => {
    if (!value) return;
    const previous = document.activeElement as HTMLElement;
    dialog.current?.showModal(); cancel.current?.focus();
    return () => { dialog.current?.close(); previous?.focus(); };
  }, [value]);
  if (!value) return null;
  return <dialog ref={dialog} aria-labelledby={title} onCancel={e => { e.preventDefault(); close(); }}><div className="dialog-body"><button className="icon-button dialog-close" aria-label="Đóng xác nhận" onClick={close}><X size={20}/></button><h2 id={title}>{value.title}</h2><p>{value.description}</p><div className="actions"><button ref={cancel} onClick={close}>Hủy</button><button className={value.danger ? 'danger' : 'primary'} onClick={() => { close(); void value.action(); }}>{value.confirmLabel}</button></div></div></dialog>;
}
