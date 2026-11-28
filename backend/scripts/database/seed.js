const { readFile } = require('node:fs/promises');
const path = require('node:path');
const { loadConfig, loadEnv, root } = require('../../src/config');
const { createPool } = require('../../src/database/pool');
const { migrate } = require('../../src/database/migrate');
const { bootstrap } = require('../../src/database/bootstrap');
const { seed } = require('../../src/database/seed');

async function main() {
  loadEnv(); const config = loadConfig(), pool = createPool(config);
  try {
    await migrate(pool); await bootstrap(pool, config);
    const library = JSON.parse(await readFile(path.resolve(root, '../mobile/assets/content/reference_library.json'), 'utf8'));
    const snapshot = JSON.parse(await readFile(path.resolve(root, '../mobile/assets/content/offline_snapshot.json'), 'utf8'));
    console.log(JSON.stringify(await seed(pool, config, library, snapshot)));
  } finally { await pool.end(); }
}

main().catch(err => { console.error('Seed failed:', err.message); process.exitCode = 1; });
