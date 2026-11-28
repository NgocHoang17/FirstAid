const { loadConfig, loadEnv } = require('./config');
const { createPool } = require('./database/pool');
const { migrate } = require('./database/migrate');
const { bootstrap } = require('./database/bootstrap');
const { createApp } = require('./app');
async function main() {
  loadEnv();
  const config = loadConfig(), pool = createPool(config);
  try {
    await migrate(pool); await bootstrap(pool, config);
    const app = createApp(pool, config);
    const server = app.listen(config.port, config.host, () => process.stdout.write(`FirstAid API listening on ${config.host}:${config.port}\n`));
    server.requestTimeout = 45000; server.headersTimeout = 10000;
    let closing = false;
    const shutdown = () => {
      if (closing) return; closing = true;
      const timer = setTimeout(() => process.exit(1), 10000).unref();
      server.close(async () => { app.locals.sessionStore.close(); await pool.end(); clearTimeout(timer); });
      server.closeIdleConnections();
    };
    process.once('SIGINT', shutdown); process.once('SIGTERM', shutdown);
    server.on('error', async () => { process.stderr.write('Cannot start HTTP server\n'); app.locals.sessionStore.close(); await pool.end(); process.exitCode = 1; });
  } catch (err) { await pool.end(); throw err; }
}
if (require.main === module) main().catch(err => { process.stderr.write(`Backend startup failed (${err.code || err.name}). Check configuration and migration history.\n`); process.exitCode = 1; });
module.exports = { main };
