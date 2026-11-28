const { test } = require('node:test');
const assert = require('node:assert/strict');
const { clearCurrentIncident, queryInput } = require('../../src/modules/assistant/assistant.service');
const { checks: C } = require('../../src/shared/api');
const { normalizeImage } = require('../../src/modules/media/media.service');
const sharp = require('sharp');
const { loadConfig } = require('../../src/config');
const { randomUUID } = require('node:crypto');
const { flywayChecksum } = require('../../src/database/migrate');
const { Catalog } = require('../../src/modules/catalog/catalog.service');
const { searchCatalog } = require('../../src/shared/query-params');
const { createPool } = require('../../src/database/pool');
const { Client } = require('pg');

test('explicit database credentials reach pg with URL escaping and override URL credentials', async () => {
  for (const databaseUrl of ['postgresql://localhost/firstaid', 'postgresql://old:old@localhost/firstaid?application_name=test']) {
    const pool = createPool({ databaseUrl, databaseUser: 'test@user', databasePassword: 'p:a/ss#word' });
    const client = new Client(pool.options);
    assert.equal(client.connectionParameters.user, 'test@user');
    assert.equal(client.connectionParameters.password, 'p:a/ss#word');
    assert.equal(client.connectionParameters.database, 'firstaid');
    await pool.end();
  }
  const pool = createPool({ databaseUrl: 'postgresql://url_user:url_password@localhost/firstaid', databaseUser: '', databasePassword: '' });
  const client = new Client(pool.options);
  assert.equal(client.connectionParameters.user, 'url_user');
  assert.equal(client.connectionParameters.password, 'url_password');
  await pool.end();
});

test('category writes reject codes outside the mobile catalogue before querying the database', async () => {
  const catalog = new Catalog({ query() { throw new Error('Unexpected database call'); } });
  for (const code of ['FA00', 'FA19', 'FA99']) {
    await assert.rejects(catalog.saveCategory(null, { code }), error => error.status === 400 && error.fields[0].field === 'code');
  }
});

test('catalogue search matches names and codes without accents and treats wildcards literally', () => {
  const items = [
    { code: 'FA01', name: 'Đánh giá ban đầu' },
    { code: 'PNT2024', title: 'CẨM NANG SƠ CẤP CỨU', publisher: 'Đại học' },
  ];
  assert.deepEqual(searchCatalog(items, 'danh gia'), [items[0]]);
  assert.deepEqual(searchCatalog(items, 'cam nang'), [items[1]]);
  assert.deepEqual(searchCatalog(items, 'pnt2024'), [items[1]]);
  assert.deepEqual(searchCatalog(items, 'DAI HOC'), [items[1]]);
  assert.deepEqual(searchCatalog(items, '%'), []);
  assert.deepEqual(searchCatalog(items, '  '), items);
});
test('Flyway CRC32 matches the standard vector and ignores BOM/line endings', () => {
  assert.equal(flywayChecksum('123456789'), -873187034);
  assert.equal(flywayChecksum('\uFEFF123\n456\r\n789'), -873187034);
});
test('preserves emergency gate without treating educational questions as incidents', () => {
  assert.equal(clearCurrentIncident('Người trước mặt tôi đang không thở'), true);
  assert.equal(clearCurrentIncident('Bạn tôi đang bất tỉnh'), true);
  assert.equal(clearCurrentIncident('Tôi đang học về người không thở trong bài học'), false);
  assert.equal(clearCurrentIncident('Giải thích kiến thức về bất tỉnh'), false);
});
test('validates request IDs, age and bounded user context', () => {
  const input = { client_request_id: randomUUID(), message: '  câu hỏi  ', age_group: null, context_mode: 'learning', context_messages: [' trước đó '] };
  assert.equal(queryInput(input).message, 'câu hỏi');
  assert.deepEqual(queryInput(input).context_messages, ['trước đó']);
  for (const changes of [{ client_request_id: 'bad' }, { message: ' ' }, { age_group: 'INFANT' }, { context_messages: Array(5).fill('x') }, { context_messages: ['x'.repeat(2001)] }, { context_mode: 'emergency' }]) assert.throws(() => queryInput({ ...input, ...changes }));
  for (const bad of [null, [], 'text']) assert.throws(() => queryInput(bad));
});
test('rejects revisions with fractional or unsafe values', () => {
  for (const bad of [null, 0, -1, 1.5, '1', 9007199254740992]) assert.throws(() => C.revision({ expected_revision: bad }));
  assert.equal(C.revision({ expected_revision: 2 }), 2);
});
test('image decoder re-encodes pixels and drops metadata/trailing data', async () => {
  const png = await sharp({ create: { width: 20, height: 12, channels: 3, background: '#f00' } }).png().toBuffer();
  const bytes = Buffer.concat([png, Buffer.from('untrusted trailing data')]);
  const result = await normalizeImage(bytes);
  assert.equal(result.mime, 'image/png'); assert.equal(result.width, 20); assert.equal(result.height, 12);
  assert.equal(result.bytes.includes(Buffer.from('untrusted trailing data')), false);
  const jpg = await sharp(png).jpeg().withMetadata({ exif: { IFD0: { Copyright: 'private metadata' } } }).toBuffer();
  const clean = await normalizeImage(jpg);
  assert.equal((await sharp(clean.bytes).metadata()).exif, undefined);
});
test('rejects arbitrary bytes, disguised formats, overlarge input and pixel bombs', async () => {
  for (const bytes of [Buffer.from('<svg onload="alert(1)"/>'), Buffer.from([1, 2, 3])]) await assert.rejects(normalizeImage(bytes), { status: 400 });
  const png = await sharp({ create: { width: 2, height: 2, channels: 3, background: '#fff' } }).png().toBuffer();
  await assert.rejects(normalizeImage(png, 'image/jpeg', true), { status: 415 });
  const huge = await sharp({ create: { width: 4001, height: 4000, channels: 3, background: '#fff' } }).png().toBuffer();
  await assert.rejects(normalizeImage(huge, 'image/png', true), { status: 413 });
  await assert.rejects(normalizeImage(Buffer.alloc(5242881)), { status: 413 });
});
test('configuration accepts legacy JDBC URLs while requiring a session secret', () => {
  assert.throws(() => loadConfig({}));
  const config = loadConfig({ SESSION_SECRET: 'a'.repeat(32), DB_URL: 'jdbc:postgresql://localhost:5432/firstaid' });
  assert.equal(config.databaseUrl, 'postgresql://localhost:5432/firstaid');
  assert.equal(config.cookieSecure, true);
  assert.equal(config.assetKeys.size > 0, true);
});
