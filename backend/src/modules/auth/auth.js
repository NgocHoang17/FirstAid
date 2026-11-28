const { randomBytes, timingSafeEqual } = require('node:crypto');
const bcrypt = require('bcryptjs');
const session = require('express-session');
const PgStore = require('connect-pg-simple')(session);
const { Router } = require('express');
const { ApiFailure, invalid, checks: C, ok, Limiter } = require('../../shared/api');
const callSession = (req, method) => new Promise((resolve, reject) => req.session[method](err => err ? reject(err) : resolve()));
const authRequired = () => new ApiFailure(401, 'AUTH_REQUIRED', 'Cần đăng nhập Admin');
const cookieName = 'JSESSIONID';
const csrfToken = () => randomBytes(32).toString('hex');
function auth(pool, config) {
  const store = new PgStore({ pool, tableName: 'admin_sessions', createTableIfMissing: false, pruneSessionInterval: 900 });
  const middleware = session({ store, secret: config.sessionSecret, name: cookieName, resave: false, saveUninitialized: false,
    cookie: { httpOnly: true, secure: config.cookieSecure, sameSite: 'lax', maxAge: 30 * 60 * 1000, path: '/' } });
  const router = Router(), limiter = new Limiter(10, 600000);
  const requireAdmin = async (req, res, next) => {
    if (!req.session.adminId) throw authRequired();
    const admin = (await pool.query('SELECT id,username FROM admin_users WHERE id=$1 AND enabled=true', [req.session.adminId])).rows[0];
    if (!admin) throw authRequired();
    req.admin = { ...admin, role: 'ADMIN' }; next();
  };
  const csrf = (req, res, next) => {
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) return next();
    const expected = req.session.csrf, actual = req.get('X-CSRF-TOKEN');
    if (typeof actual !== 'string' || !expected || Buffer.byteLength(actual) !== Buffer.byteLength(expected) || !timingSafeEqual(Buffer.from(actual), Buffer.from(expected))) throw new ApiFailure(403, 'CSRF_INVALID', 'CSRF token không hợp lệ');
    next();
  };
  router.get('/csrf', async (req, res) => {
    if (!req.session.csrf) req.session.csrf = csrfToken();
    await callSession(req, 'save');
    res.json(ok({ token: req.session.csrf, header_name: 'X-CSRF-TOKEN' }));
  });
  router.post('/login', async (req, res) => {
    const username = C.text(req.body, 'username', 100, true), password = req.body.password;
    if (typeof password !== 'string' || !password.length || password.length > 200) throw invalid('password');
    limiter.check(req.ip);
    const admin = (await pool.query('SELECT id,username,password_hash,enabled FROM admin_users WHERE username=$1', [username])).rows[0];
    // A fixed dummy hash prevents the unknown-user path from skipping password work.
    const valid = await bcrypt.compare(password, admin?.password_hash || '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');
    if (!admin?.enabled || !valid) throw new ApiFailure(401, 'INVALID_CREDENTIALS', 'Thông tin đăng nhập không đúng');
    await callSession(req, 'regenerate');
    req.session.adminId = admin.id; req.session.csrf = csrfToken();
    await callSession(req, 'save');
    res.json(ok({ id: admin.id, username: admin.username, role: 'ADMIN' }));
  });
  router.get('/me', requireAdmin, (req, res) => res.json(ok(req.admin)));
  router.post('/logout', requireAdmin, async (req, res) => {
    await callSession(req, 'destroy');
    res.clearCookie(cookieName, { path: '/', httpOnly: true, secure: config.cookieSecure, sameSite: 'lax' }).status(204).end();
  });
  return { middleware, router, requireAdmin, csrf, store };
}
module.exports = { auth };
