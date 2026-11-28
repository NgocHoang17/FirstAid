const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawn, execFile } = require('node:child_process');
const { promisify } = require('node:util');
const { once } = require('node:events');
const { createServer } = require('node:net');
const path = require('node:path');
const { database } = require('../helpers/integration');
const run = promisify(execFile);
test('CLI migrates/seeds, boots the server and passes the existing PowerShell smoke script', { timeout: 40000 }, async t => {
  const { config, pool } = await database(t, false);
  const probe = createServer();
  await new Promise(resolve => probe.listen(0, '127.0.0.1', resolve));
  const port = probe.address().port;
  await new Promise(resolve => probe.close(resolve));
  const cwd = path.resolve(__dirname, '../..');
  const env = { ...process.env, DATABASE_URL: config.databaseUrl, SESSION_SECRET: config.sessionSecret, SESSION_COOKIE_SECURE: 'false',
    ADMIN_SEED_USERNAME: config.seedUsername, ADMIN_SEED_PASSWORD: config.seedPassword, PUBLIC_REGION: 'VN-PILOT', EMERGENCY_NUMBER: '115', PORT: String(port), HOST: '127.0.0.1',
    DB_USER: '', DB_PASSWORD: '', AI_BASE_URL: '', AI_INTERNAL_TOKEN: '', TEST_ADMIN_USERNAME: config.seedUsername, TEST_ADMIN_PASSWORD: config.seedPassword };
  const options = { cwd, env, windowsHide: true, timeout: 20000 };
  assert.match((await run(process.execPath, ['scripts/database/migrate.js'], options)).stdout, /migrations applied/);
  assert.match((await run(process.execPath, ['scripts/database/seed.js'], options)).stdout, /"status":"imported"/);
  assert.match((await run(process.execPath, ['scripts/database/seed.js'], options)).stdout, /preserved_existing_data/);
  const server = spawn(process.execPath, ['src/server.js'], { cwd, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  let output = ''; server.stdout.on('data', b => { output += b; }); server.stderr.on('data', b => { output += b; });
  const closed = once(server, 'close');
  try {
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => { clearInterval(interval); reject(new Error('Server failed to start: ' + output)); }, 10000);
      const interval = setInterval(() => {
        if (output.includes('listening')) { clearTimeout(timer); clearInterval(interval); resolve(); }
        else if (server.exitCode !== null) { clearTimeout(timer); clearInterval(interval); reject(new Error(output)); }
      }, 20);
    });
    const base = 'http://127.0.0.1:' + port + '/api/v1';
    const response = await fetch(base + '/categories'); assert.equal(response.status, 200);
    assert.equal((await response.json()).data.items.length, 18);
    if (process.platform === 'win32') {
      const result = await run('powershell.exe', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'scripts/smoke/api.ps1', '-BaseUrl', base], options);
      assert.match(result.stdout, /PASS: auth\/CSRF/);
    }
    assert.equal((await pool.query('SELECT count(*) FROM node_schema_history')).rows[0].count, 4);
  } finally { server.kill(); await closed; }
});
