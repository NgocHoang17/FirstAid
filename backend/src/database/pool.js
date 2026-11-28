const { Pool, types } = require('pg');
// Public revisions are JSON numbers; reject values that cannot be represented exactly.
types.setTypeParser(20, v => { const n = Number(v); if (!Number.isSafeInteger(n)) throw new Error('Unsafe bigint'); return n; });
function createPool(config) {
  const pool = new Pool({ connectionString: config.databaseUrl, ...(config.databaseUser ? { user: config.databaseUser } : {}),
    ...(config.databasePassword !== undefined ? { password: config.databasePassword } : {}),
    max: 10, connectionTimeoutMillis: 5000, idleTimeoutMillis: 30000 });
  pool.on('error', () => process.stderr.write('Idle database connection failed\n'));
  return pool;
}
async function transaction(pool, work, readOnly = false) {
  const client = await pool.connect();
  try {
    await client.query(readOnly ? 'BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY' : 'BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (error) { await client.query('ROLLBACK'); throw error; }
  finally { client.release(); }
}
module.exports = { createPool, transaction };
