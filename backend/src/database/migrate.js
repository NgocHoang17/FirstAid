const { readFile, readdir } = require('node:fs/promises');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { root } = require('../config');
const { transaction } = require('./pool');

// Flyway SQL checksums ignore line separators and the initial UTF-8 BOM.
function flywayChecksum(sql) {
  let crc = 0xffffffff;
  for (const byte of Buffer.from(sql.replace(/^\uFEFF/, '').split(/\r\n|\r|\n/).join(''), 'utf8')) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) | 0;
}
async function migrate(pool) {
  const directory = path.join(root, 'db/migrations');
  const files = (await readdir(directory)).filter(f => /^V\d+__.+\.sql$/.test(f)).sort((a, b) => Number(a.match(/\d+/)[0]) - Number(b.match(/\d+/)[0]));
  await transaction(pool, async db => {
    await db.query('SELECT pg_advisory_xact_lock(20261128, 1)');
    const history = await db.query("SELECT to_regclass('node_schema_history') AS node, to_regclass('flyway_schema_history') AS flyway, to_regclass('articles') AS articles");
    const state = history.rows[0];
    if (!state.node && !state.flyway && state.articles) throw new Error('Database has tables without migration history; restore/verify history before migration');
    await db.query(`CREATE TABLE IF NOT EXISTS node_schema_history (
      version integer PRIMARY KEY, script text NOT NULL, checksum text NOT NULL, installed_at timestamptz NOT NULL DEFAULT now())`);
    const applied = new Map((await db.query('SELECT * FROM node_schema_history')).rows.map(r => [r.version, r]));
    const legacy = state.flyway ? (await db.query('SELECT version,script,checksum,success FROM flyway_schema_history WHERE version IS NOT NULL')).rows : [];
    if (legacy.some(r => !r.success)) throw new Error('Unsuccessful Flyway migration; repair the database first');
    const knownVersions = new Set(files.map(f => Number(f.match(/\d+/)[0])));
    if ([...applied.keys(), ...legacy.map(r => Number(r.version))].some(v => !knownVersions.has(v))) throw new Error('Database migration is newer than this backend');
    for (const file of files) {
      const version = Number(file.match(/\d+/)[0]);
      const sql = await readFile(path.join(directory, file), 'utf8');
      const checksum = createHash('sha256').update(sql.replace(/\r\n/g, '\n')).digest('hex');
      const previous = applied.get(version);
      const flyway = legacy.find(r => Number(r.version) === version);
      if (previous) {
        if (previous.script !== file || previous.checksum !== checksum) throw new Error(`Migration checksum mismatch: ${file}`);
        continue;
      }
      if (flyway) {
        if (flyway.script !== file || flyway.checksum !== flywayChecksum(sql)) throw new Error(`Flyway checksum mismatch: ${file}`);
      } else await db.query(sql);
      await db.query('INSERT INTO node_schema_history(version,script,checksum) VALUES($1,$2,$3)', [version, file, checksum]);
    }
  });
}
module.exports = { migrate, flywayChecksum };
