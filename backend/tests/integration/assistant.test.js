const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { createServer } = require('node:http');
const sharp = require('sharp');
const { fixture } = require('../helpers/integration');
const { fallback } = require('../../src/modules/assistant/assistant.service');

test('text and image gateways validate provenance, age, multipart and upstream failures', async t => {
  let f, requests = 0;
  const upstream = createServer(async (req, res) => {
    requests++;
    assert.equal(req.headers['x-internal-token'], f.config.aiToken);
    const chunks = []; for await (const chunk of req) chunks.push(chunk);
    const bytes = Buffer.concat(chunks);
    let input;
    if (req.url.endsWith('query-with-image')) {
      const request = new Request('http://fixture/', { method: 'POST', headers: { 'Content-Type': req.headers['content-type'] }, body: bytes });
      const form = await request.formData();
      assert.deepEqual([...form.keys()].sort(), ['image', 'request']);
      input = JSON.parse(await form.get('request').text());
      assert.equal(Object.hasOwn(input, 'client_request_id'), false);
      assert.equal(form.get('image').type, 'image/png');
      const cleaned = Buffer.from(await form.get('image').arrayBuffer());
      assert.equal(cleaned.includes(Buffer.from('untrusted trailing data')), false);
    } else input = JSON.parse(bytes.toString());
    if (input.message.startsWith('upstream-')) {
      const code = Number(input.message.slice(9)); res.writeHead(code); res.end('{}'); return;
    }
    const source = f.library.sources.find(s => s.code === 'PNT2024');
    const adult = f.snapshot.articles.find(a => a.age_group === 'ADULT' && a.references.some(r => r.source_id === source.id));
    const base = fallback(input.request_id, 'answered');
    base.answer_blocks = [{ text: 'Contract fixture only', citation_ids: ['c1'], kind: 'paragraph' }];
    base.citations = [{ id: 'c1', evidence_id: 'fixture-only', source_id: source.id, source_revision: source.revision,
      source_title: 'Untrusted model title', page_start: 10, page_end: 10, article_id: null, article_revision: null, original_url: 'https://untrusted.invalid/' }];
    const c = base.citations[0];
    if (input.message === 'stale-source') c.source_revision++;
    if (input.message === 'invalid-page') c.page_end = 100000;
    if (input.message === 'missing-source') c.source_id = randomUUID();
    if (input.message === 'wrong-article-age' || input.message === 'stale-article' || input.message === 'valid-adult') {
      c.article_id = adult.id; c.article_revision = adult.content_revision + (input.message === 'stale-article' ? 1 : 0);
    }
    if (input.message === 'unpublished') { c.article_id = f.draftId; c.article_revision = 1; }
    if (input.message === 'duplicate') base.citations.push({ ...c });
    if (input.message === 'unknown-block-id') base.answer_blocks[0].citation_ids = ['missing'];
    if (input.message === 'wrong-id') base.request_id = randomUUID();
    if (input.message === 'missing-key') delete base.corpus_version;
    if (input.message === 'invalid-status') base.status = 'invented';
    if (input.message === 'emergency') { Object.assign(base, fallback(input.request_id, 'emergency_redirect'), { safety_message_code: 'CONTACT_HELP' }); }
    if (input.message === 'clarify') { Object.assign(base, fallback(input.request_id, 'clarification_needed'), { clarification_question: 'Câu hỏi fixture?' }); }
    if (input.message === 'suggestions') { base.suggested_article_id = adult.id; base.suggested_category_code = 'FA99'; }
    if (input.message === 'huge-response') { res.writeHead(200); res.end('x'.repeat(1024 * 1024 + 1)); return; }
    res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(base));
  });
  await new Promise(resolve => upstream.listen(0, '127.0.0.1', resolve));
  t.after(async () => { upstream.closeAllConnections(); await new Promise(resolve => upstream.close(resolve)); });
  f = await fixture(t); f.config.aiBaseUrl = 'http://127.0.0.1:' + upstream.address().port;
  const ask = (message, age = null) => f.request('/assistant/query', { method: 'POST', body: { client_request_id: randomUUID(), message, context_mode: 'learning', age_group: age } });
  await t.test('maps database titles and discards model URLs; preserves correlated request IDs', async () => {
    const input = { client_request_id: randomUUID(), message: 'valid', context_mode: 'learning' };
    const r = await f.request('/assistant/query', { method: 'POST', body: input });
    assert.equal(r.status, 200); assert.equal(r.data.status, 'answered');
    assert.equal(r.data.request_id, input.client_request_id); assert.equal(r.data.citations[0].source_title, 'CẨM NANG SƠ CẤP CỨU');
    assert.equal(Object.hasOwn(r.data.citations[0], 'original_url'), false);
    for (const message of ['stale-source', 'invalid-page', 'missing-source', 'duplicate', 'unknown-block-id']) {
      const invalid = await ask(message); assert.equal(invalid.data.status, 'insufficient_evidence', message); assert.deepEqual(invalid.data.answer_blocks, []);
    }
  });
  await t.test('rejects incorrect IDs/shapes, stale articles and age mismatches; filters suggestions', async () => {
    for (const message of ['wrong-id', 'missing-key', 'invalid-status', 'huge-response']) assert.equal((await ask(message)).data.status, 'unavailable', message);
    assert.equal((await ask('wrong-article-age', 'CHILD')).data.status, 'insufficient_evidence');
    assert.equal((await ask('wrong-article-age')).data.status, 'insufficient_evidence');
    assert.equal((await ask('valid-adult', 'ADULT')).data.status, 'answered');
    assert.equal((await ask('stale-article', 'ADULT')).data.status, 'insufficient_evidence');
    const suggestion = await ask('suggestions', 'CHILD');
    assert.equal(suggestion.data.suggested_article_id, null); assert.equal(suggestion.data.suggested_category_code, null);
    await f.login();
    const a = structuredClone(f.snapshot.articles.find(a => a.age_group === 'ALL'));
    delete a.id; a.slug = randomUUID(); a.variant_key = randomUUID(); for (const s of a.steps) delete s.id;
    const draft = await f.request('/admin/articles', { method: 'POST', admin: true, body: a }); assert.equal(draft.status, 201); f.draftId = draft.data.id;
    assert.equal((await ask('unpublished', 'ALL')).data.status, 'insufficient_evidence');
  });
  await t.test('emergency gate runs before AI; other statuses and failures remain controlled', async () => {
    const before = requests;
    const emergency = await ask('Người trước mặt tôi đang không thở');
    assert.equal(emergency.data.status, 'emergency_redirect'); assert.equal(emergency.data.safety_message_code, 'CONTACT_HELP'); assert.equal(requests, before);
    assert.equal((await ask('emergency')).data.status, 'emergency_redirect');
    assert.equal((await ask('clarify')).data.status, 'clarification_needed');
    assert.equal((await ask('upstream-503')).data.status, 'unavailable');
    const previous = f.config.aiBaseUrl; f.config.aiBaseUrl = '';
    assert.equal((await ask('valid')).data.status, 'unavailable'); f.config.aiBaseUrl = previous;
  });
  const image = await sharp({ create: { width: 40, height: 40, channels: 3, background: '#abc' } }).png().toBuffer();
  const form = (message = 'valid', bytes = image, mime = 'image/png', fileRequest = true) => {
    const b = new FormData(), text = JSON.stringify({ client_request_id: randomUUID(), message, context_mode: 'learning' });
    b.append('request', fileRequest ? new Blob([text], { type: 'application/json' }) : text);
    b.append('image', new Blob([bytes], { type: mime }), 'image.png'); return b;
  };
  const askImage = body => f.request('/assistant/query-with-image', { method: 'POST', body });
  await t.test('forwards exactly two normalized multipart parts and supports Flutter JSON files', async () => {
    const r = await askImage(form('valid', Buffer.concat([image, Buffer.from('untrusted trailing data')])));
    assert.equal(r.status, 200); assert.equal(r.data.status, 'answered');
    assert.equal((await askImage(form('valid', image, 'image/png', false))).data.status, 'answered');
    assert.equal((await askImage(form('stale-source'))).data.status, 'insufficient_evidence');
    for (const status of [400, 413, 415]) {
      const r = await askImage(form('upstream-' + status)); assert.equal(r.status, status);
      assert.equal(r.error.code, { 400: 'VALIDATION_ERROR', 413: 'IMAGE_TOO_LARGE', 415: 'IMAGE_UNSUPPORTED' }[status]);
    }
  });
  await t.test('rejects missing/duplicate parts, invalid JSON, MIME tricks, corrupt and overlarge images', async () => {
    assert.equal((await askImage(new FormData())).status, 400);
    const duplicate = form(); duplicate.append('request', '{}'); assert.equal((await askImage(duplicate)).status, 400);
    const invalid = form(); invalid.set('request', '{invalid'); assert.equal((await askImage(invalid)).status, 400);
    assert.equal((await askImage(form('valid', image, 'image/jpeg'))).status, 415);
    assert.equal((await askImage(form('valid', Buffer.from('<svg/>')))).status, 415);
    assert.equal((await askImage(form('valid', Buffer.alloc(5242881)))).status, 413);
    const bomb = await sharp({ create: { width: 4001, height: 4000, channels: 3, background: '#fff' } }).png().toBuffer();
    assert.equal((await askImage(form('valid', bomb))).status, 413);
  });
  await t.test('timeouts return unavailable and the image concurrency limit releases slots', async () => {
    // Slow local HTTP endpoint, no provider credentials or real user images.
    const slow = createServer((req, res) => { req.resume(); });
    await new Promise(resolve => slow.listen(0, '127.0.0.1', resolve));
    const old = f.config.aiBaseUrl; f.config.aiBaseUrl = 'http://127.0.0.1:' + slow.address().port;
    f.config.aiImageTimeoutMs = 200; f.config.aiTimeoutMs = 30;
    try {
      assert.equal((await ask('timeout')).data.status, 'unavailable');
      const results = await Promise.all([askImage(form()), askImage(form()), askImage(form())]);
      assert.deepEqual(results.map(r => r.status).sort(), [200, 200, 429]);
      assert.equal(results.filter(r => r.status === 200).every(r => r.data.status === 'unavailable'), true);
      assert.equal((await askImage(form())).data.status, 'unavailable');
    } finally { f.config.aiBaseUrl = old; slow.closeAllConnections(); await new Promise(resolve => slow.close(resolve)); }
  });
  await t.test('shared chat rate limit returns Retry-After', async () => {
    f.config.aiMaxPerMinute = 1;
    // Separate app instance gets its own process-local limiter.
    const { createApp } = require('../../src/app'); const app = createApp(f.pool, f.config);
    const server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
    try {
      const url = 'http://127.0.0.1:' + server.address().port + '/api/v1/assistant/query';
      const init = { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ client_request_id: randomUUID(), message: 'valid', context_mode: 'learning' }) };
      assert.equal((await fetch(url, init)).status, 200);
      const limited = await fetch(url, init); assert.equal(limited.status, 429); assert.equal(limited.headers.get('retry-after'), '60');
    } finally { await app.locals.sessionStore.close(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
  });
});
