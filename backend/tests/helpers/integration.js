const { randomUUID } = require('node:crypto');
const { createPool } = require('../../src/database/pool');
const { loadConfig } = require('../../src/config');
const { migrate } = require('../../src/database/migrate');
const { bootstrap } = require('../../src/database/bootstrap');
const { createApp } = require('../../src/app');
const { seed } = require('../../src/database/seed');
const { readFile } = require('node:fs/promises');
const path = require('node:path');

async function database(t, runMigration = true) {
  if (!process.env.TEST_DATABASE_URL) throw new Error('Set TEST_DATABASE_URL to a PostgreSQL test database. Tests create and remove only their own unique schemas.');
  const schema = 'firstaid_test_' + randomUUID().replaceAll('-', '');
  const config = loadConfig({ DATABASE_URL: process.env.TEST_DATABASE_URL, SESSION_SECRET: 'test-only-session-secret-at-least-32-characters',
    SESSION_COOKIE_SECURE: 'false', PUBLIC_REGION: 'VN-DN', EMERGENCY_NUMBER: '115', ADMIN_ORIGIN: 'http://127.0.0.1:5173',
    ADMIN_SEED_USERNAME: 'integration-admin', ADMIN_SEED_PASSWORD: 'integration-password-only', AI_INTERNAL_TOKEN: 'integration-internal-token', AI_MAX_PER_MINUTE: '200' });
  const adminPool = createPool(config);
  await adminPool.query(`CREATE SCHEMA "${schema}"`);
  const url = new URL(config.databaseUrl); url.searchParams.set('options', `-c search_path=${schema}`);
  config.databaseUrl = url.toString();
  const pool = createPool(config);
  t.after(async () => {
    await pool.end();
    await adminPool.query(`DROP SCHEMA "${schema}" CASCADE`);
    await adminPool.end();
  });
  if (runMigration) { await migrate(pool); await bootstrap(pool, config); }
  return { pool, config, schema };
}
async function fixture(t, options = {}) {
  const { pool, config } = await database(t);
  const contentRoot = path.resolve(__dirname, '../../..', 'mobile/assets/content');
  const library = JSON.parse(await readFile(path.join(contentRoot, 'reference_library.json'), 'utf8'));
  const snapshot = JSON.parse(await readFile(path.join(contentRoot, 'offline_snapshot.json'), 'utf8'));
  await seed(pool, config, library, snapshot);
  const app = createApp(pool, config, options);
  const server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
  t.after(async () => { app.locals.sessionStore.close(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); });
  const base = 'http://127.0.0.1:' + server.address().port + '/api/v1';
  let cookie = '', csrf = '';
  const request = async (route, { method = 'GET', body, admin = false, token = true, headers = {} } = {}) => {
    const response = await fetch(base + route, { method, headers: { ...(admin && cookie ? { Cookie: cookie } : {}),
      ...(admin && token && csrf ? { 'X-CSRF-TOKEN': csrf } : {}),
      ...(body !== undefined && !(body instanceof FormData) ? { 'Content-Type': 'application/json' } : {}), ...headers },
      body: body instanceof FormData ? body : body === undefined ? undefined : JSON.stringify(body) });
    if (admin && response.headers.getSetCookie().length) cookie = response.headers.getSetCookie()[0].split(';')[0];
    const json = await response.json().catch(() => null);
    return { status: response.status, data: json?.data, error: json?.error, headers: response.headers, json };
  };
  const refresh = async () => { const r = await request('/admin/auth/csrf', { admin: true }); csrf = r.data.token; return r; };
  const login = async () => {
    await refresh();
    const r = await request('/admin/auth/login', { method: 'POST', admin: true, body: { username: config.seedUsername, password: config.seedPassword } });
    if (r.status !== 200) throw new Error(JSON.stringify(r));
    await refresh(); return r;
  };
  return { pool, config, library, snapshot, app, request, login, refresh, base };
}
module.exports = { database, fixture };
