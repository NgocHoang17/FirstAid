// Local contract fixture only. Never use as a production AI provider.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const library = JSON.parse(fs.readFileSync(path.join(__dirname, '../../mobile/assets/content/reference_library.json'), 'utf8'));
const source = library.sources.find(s => s.code === 'PNT2024');

http.createServer((request, response) => {
  if (request.url !== '/internal/v1/query' || request.method !== 'POST'
      || request.headers['x-internal-token'] !== 'LocalInternalTestToken') {
    response.writeHead(404).end();
    return;
  }
  const chunks = [];
  request.on('data', chunk => chunks.push(chunk));
  request.on('end', () => {
    const input = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    const status = input.message === 'emergency' ? 'emergency_redirect' : 'answered';
    const citation = {
      id: 'c1', evidence_id: 'fixture-only', source_id: source.id,
      source_revision: input.message === 'stale' ? 999 : source.revision,
      source_title: 'Untrusted model title', page_start: 10, page_end: 10,
      article_id: null, article_revision: null,
    };
    const output = {
      request_id: input.request_id, status,
      answer_blocks: status === 'answered' ? [{ text: 'Chỉ kiểm thử contract, không dùng để sơ cứu', citation_ids: ['c1'] }] : [],
      citations: status === 'answered' ? [citation] : [],
      suggested_category_code: null, suggested_article_id: null,
      safety_message_code: status === 'emergency_redirect' ? 'CONTACT_HELP' : null,
      clarification_question: null, corpus_version: 'fixture-only',
    };
    response.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    response.end(JSON.stringify(output));
  });
}).listen(18081, '127.0.0.1', () => process.stdout.write('Mock AI fixture listening on 127.0.0.1:18081\n'));
