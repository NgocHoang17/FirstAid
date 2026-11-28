const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFile } = require('node:fs/promises');
const path = require('node:path');
const { database } = require('../helpers/integration');
const { migrate, flywayChecksum } = require('../../src/database/migrate');
const { bootstrap } = require('../../src/database/bootstrap');
const { seed } = require('../../src/database/seed');
test('migrations initialize a fresh database and are idempotent', async t => {
  const { pool, config } = await database(t);
  assert.equal((await pool.query('SELECT count(*) FROM node_schema_history')).rows[0].count, 4);
  await migrate(pool);
  assert.equal((await pool.query('SELECT count(*) FROM node_schema_history')).rows[0].count, 4);
  const hash = (await pool.query('SELECT password_hash FROM admin_users')).rows[0].password_hash;
  await bootstrap(pool, { ...config, seedPassword: 'different-password-only' });
  assert.equal((await pool.query('SELECT password_hash FROM admin_users')).rows[0].password_hash, hash);
  const snapshot = JSON.parse(await readFile(path.resolve(__dirname, '../../../mobile/assets/content/offline_snapshot.json'), 'utf8'));
  const library = JSON.parse(await readFile(path.resolve(__dirname, '../../../mobile/assets/content/reference_library.json'), 'utf8'));
  assert.equal((await seed(pool, config, library, snapshot)).status, 'imported');
  await pool.query("UPDATE articles SET title='existing admin edit' WHERE id=$1", [snapshot.articles[0].id]);
  assert.equal((await seed(pool, config, library, snapshot)).status, 'preserved_existing_data');
  assert.equal((await pool.query('SELECT title FROM articles WHERE id=$1', [snapshot.articles[0].id])).rows[0].title, 'existing admin edit');
});
test('adopts verified Flyway V1–V3 without rebuilding or losing domain data', async t => {
  const { pool } = await database(t, false);
  await pool.query('CREATE TABLE flyway_schema_history(version text,script text,checksum integer,success boolean)');
  for (const file of ['V1__schema.sql', 'V2__reference_metadata.sql', 'V3__step_media.sql']) {
    const sql = await readFile(path.resolve(__dirname, '../..', 'db/migrations', file), 'utf8');
    await pool.query(sql);
    await pool.query('INSERT INTO flyway_schema_history VALUES($1,$2,$3,true)', [file[1], file, flywayChecksum(sql)]);
  }
  await pool.query("UPDATE categories SET name='preserved category' WHERE code='FA01'");
  await pool.query("INSERT INTO media_assets(id,mime_type,width,height,content) VALUES('00000000-0000-4000-8000-000000000001','image/png',1,1,$1)", [Buffer.from('fixture')]);
  const version = (await pool.query('SELECT data_version FROM public_data_state')).rows[0].data_version;
  await migrate(pool);
  assert.equal((await pool.query("SELECT name FROM categories WHERE code='FA01'")).rows[0].name, 'preserved category');
  assert.equal((await pool.query('SELECT count(*) FROM media_assets')).rows[0].count, 1);
  assert.equal((await pool.query('SELECT data_version FROM public_data_state')).rows[0].data_version, version);
  assert.equal((await pool.query('SELECT count(*) FROM admin_sessions')).rows[0].count, 0);
  assert.equal((await pool.query('SELECT count(*) FROM node_schema_history')).rows[0].count, 4);
});
test('fails closed on changed migration checksums and untracked databases', async t => {
  const { pool } = await database(t);
  await pool.query("UPDATE node_schema_history SET checksum='tampered' WHERE version=1");
  await assert.rejects(migrate(pool), /checksum mismatch/);
  const other = await database(t, false);
  await other.pool.query('CREATE TABLE articles(id integer)');
  await assert.rejects(migrate(other.pool), /without migration history/);
  assert.equal((await other.pool.query("SELECT to_regclass('node_schema_history') AS name")).rows[0].name, null);
});
