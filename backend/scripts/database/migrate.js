const { loadConfig, loadEnv } = require('../../src/config');
const { createPool } = require('../../src/database/pool');
const { migrate } = require('../../src/database/migrate');
async function main() {
  loadEnv(); const pool = createPool(loadConfig());
  try { await migrate(pool); console.log('Database migrations applied.'); } finally { await pool.end(); }
}
main().catch(err => { console.error('Migration failed:', err.message); process.exitCode = 1; });
