import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { BookOpen, Building2, Check, ChevronRight, Cross, FileText, FolderOpen, LockKeyhole, LogOut, ShieldCheck } from 'lucide-react';
import { AdminApi, ApiError } from './api';
import { Busy, ConfirmDialog, Errors, Notice, type Confirmation } from './components';
import { Editor } from './Editor';
import { ResourceList } from './ResourceList';
import { resourceLabels, type Admin, type Resource } from './models';

const icons = { articles: FileText, categories: FolderOpen, sources: BookOpen, facilities: Building2 };
export function App({ api, demo = false }: { api: AdminApi; demo?: boolean }) {
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [checking, setChecking] = useState(true); const [authError, setAuthError] = useState<unknown>();
  const [sessionExpired, setSessionExpired] = useState(false);
  const [resource, setResource] = useState<Resource>('articles'); const [id, setId] = useState<string | null>(null);
  const [confirmation, setConfirmation] = useState<Confirmation | null>(null);
  const [toast, setToast] = useState('');
  const [dirty, setDirty] = useState(false); const dirtyRef = useRef(dirty); dirtyRef.current = dirty;
  const stableSetDirty = useCallback((next: boolean) => setDirty(next), []);
  const verify = useCallback(async () => {
    setChecking(true); setAuthError(undefined);
    try { const user = await api.me(); if (user.role === 'ADMIN') { setAdmin(user); setSessionExpired(false); } else setAdmin(null); }
    catch (error) { if (!(error instanceof ApiError && error.status === 401)) setAuthError(error); }
    finally { setChecking(false); }
  }, [api]);
  useEffect(() => {
    api.onUnauthorized = () => setSessionExpired(true);
    void verify();
    return () => { api.onUnauthorized = undefined; };
  }, [api, verify]);
  useEffect(() => { if (!toast) return; const timer = setTimeout(() => setToast(''), 5000); return () => clearTimeout(timer); }, [toast]);
  useEffect(() => { const prevent = (event: BeforeUnloadEvent) => { if (dirtyRef.current) { event.preventDefault(); event.returnValue = ''; } }; window.addEventListener('beforeunload', prevent); return () => window.removeEventListener('beforeunload', prevent); }, []);
  const navigate = (nextResource: Resource, nextId: string | null = null) => {
    const action = () => { setDirty(false); setResource(nextResource); setId(nextId); window.scrollTo({ top: 0 }); };
    if (dirty) setConfirmation({ title: 'Rời trang khi chưa lưu?', description: 'Các thay đổi đang nhập sẽ không được lưu. Bạn có thể hủy để tiếp tục biên tập.', confirmLabel: 'Bỏ thay đổi và rời trang', danger: true, action }); else action();
  };
  const logout = () => setConfirmation({ title: 'Đăng xuất quản trị?', description: dirty ? 'Bạn đang có thay đổi chưa lưu. Đăng xuất sẽ bỏ những thay đổi này.' : 'Phiên quản trị hiện tại sẽ kết thúc.', confirmLabel: 'Đăng xuất', action: async () => { try { await api.logout(); setAdmin(null); setId(null); setDirty(false); setSessionExpired(false); setAuthError(undefined); } catch (error) { setAuthError(error); } } });
  if (checking) return <main className="boot"><Busy text="Đang kiểm tra phiên quản trị…"/></main>;
  return <>{!admin ? <Login api={api} demo={demo} error={authError} onLogin={user => { setAdmin(user); setSessionExpired(false); setAuthError(undefined); }}/>
    : <div className="admin-layout"><aside className="sidebar"><a className="brand" href="#" onClick={e => { e.preventDefault(); navigate('articles'); }}><span className="brand-mark"><Cross size={25} strokeWidth={3}/></span><div>FirstAid<small>KHÔNG GIAN QUẢN TRỊ</small></div></a><div className="nav-label">QUẢN LÝ NỘI DUNG</div><nav aria-label="Menu quản trị">{(Object.keys(resourceLabels) as Resource[]).map(key => { const Icon = icons[key]; return <button key={key} aria-current={key === resource ? 'page' : undefined} className={key === resource ? 'active' : ''} onClick={() => navigate(key)}><Icon size={20}/><span>{resourceLabels[key]}</span>{key === resource && <ChevronRight size={16}/>}</button>; })}</nav><div className="sidebar-note"><ShieldCheck size={24}/><strong>Thông tin có trách nhiệm</strong><p>Đối chiếu tài liệu, kiểm tra phạm vi và nguồn trước khi xuất bản.</p></div><div className="sidebar-footer"><span className="live-dot"/> FirstAid · Đồ án môn học</div></aside><div className="workspace"><header className="topbar"><div className="breadcrumb">Quản trị <ChevronRight size={14}/><strong>{resourceLabels[resource]}</strong>{id && <><ChevronRight size={14}/><span>Biên tập</span></>}</div><div className="account"><span className="avatar">{admin.username.slice(0, 1).toUpperCase()}</span><div><strong>{admin.username}</strong><small>Quản trị viên</small></div><button className="icon-button" aria-label="Đăng xuất" onClick={logout}><LogOut size={19}/></button></div></header>{demo && <div className="demo-banner">DEMO LOCAL · Thay đổi chỉ giữ trong bộ nhớ, không gửi backend hoặc mobile.</div>}<main id="main-content" className="main-content"><Errors error={authError}/>{id ? <Editor key={`${resource}-${id}`} api={api} resource={resource} id={id} back={() => navigate(resource)} confirm={setConfirmation} setDirty={stableSetDirty} notify={setToast}/> : <ResourceList key={resource} api={api} resource={resource} edit={nextId => navigate(resource, nextId)} confirm={setConfirmation} notify={setToast}/>}</main></div></div>}
    {admin && sessionExpired && <SessionGate><Notice kind="error">Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục; nội dung đang nhập vẫn được giữ.</Notice><Login api={api} demo={demo} compact onLogin={user => { setAdmin(user); setSessionExpired(false); setAuthError(undefined); setToast('Đã khôi phục phiên. Có thể thử lại thao tác.'); }}/></SessionGate>}
    <ConfirmDialog value={confirmation} close={() => setConfirmation(null)}/>{toast && <div className="toast" role="status"><Check size={18}/><span>{toast}</span><button aria-label="Đóng thông báo" onClick={() => setToast('')}>×</button></div>}
  </>;
}
function SessionGate({ children }: { children: ReactNode }) {
  const dialog = useRef<HTMLDialogElement>(null);
  useEffect(() => { dialog.current?.showModal(); }, []);
  return <dialog ref={dialog} className="session-panel" aria-label="Đăng nhập lại" onCancel={e => e.preventDefault()}>{children}</dialog>;
}
function Login({ api, demo, onLogin, error: external, compact = false }: { api: AdminApi; demo: boolean; onLogin: (user: Admin) => void; error?: unknown; compact?: boolean }) {
  const [username, setUsername] = useState(''); const [password, setPassword] = useState(''); const [busy, setBusy] = useState(false); const [error, setError] = useState<unknown>();
  return <div className={compact ? 'compact-login' : 'login-layout'}>{!compact && <aside className="login-story"><div className="brand"><span className="brand-mark"><Cross size={28}/></span>FirstAid</div><div><span className="story-tag">CÙNG XÂY DỰNG FIRSTAID</span><h1>Kiến thức rõ ràng.<br/>Tiếp cận dễ dàng.</h1><p>Chăm chút từng hướng dẫn để người dùng tìm được thông tin cần thiết khi cần.</p><div className="story-line"/><p className="story-small"><ShieldCheck size={22}/>Nội dung có nguồn · Phạm vi rõ ràng</p></div><small>Ứng dụng tham khảo sơ cứu · Đồ án môn học</small></aside>}<main className="login-main"><form className="login-card" onSubmit={async e => { e.preventDefault(); setBusy(true); setError(undefined); try { const user = await api.login(username.trim(), password); setPassword(''); onLogin(user); } catch (e) { setError(e); } finally { setBusy(false); setPassword(''); } }}><div className="login-icon"><LockKeyhole size={25}/></div><div className="eyebrow">FIRSTAID ADMIN</div><h1>{compact ? 'Đăng nhập lại' : 'Chào mừng trở lại'}</h1><p>Đăng nhập để quản lý nội dung FirstAid.</p>{demo && <Notice>Chế độ demo local: tài khoản <strong>demo</strong>, mật khẩu <strong>demo</strong>. Dữ liệu chỉnh sửa không được lưu sau khi tải lại.</Notice>}<Errors error={error || external}/><label className="field"><span>Tên đăng nhập</span><input required autoComplete="username" value={username} onChange={e => setUsername(e.target.value)} disabled={busy}/></label><label className="field"><span>Mật khẩu</span><input required type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} disabled={busy}/></label><button className="primary login-submit" disabled={busy}>{busy ? 'Đang đăng nhập…' : 'Đăng nhập'}<ChevronRight size={18}/></button><small className="login-hint">Chỉ dành cho tài khoản quản trị được cấp.</small></form></main></div>;
}
