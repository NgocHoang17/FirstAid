const { checks: C, invalid, isObject, uuidPattern, Limiter, ApiFailure } = require('../../shared/api');
const { transaction } = require('../../database/pool');
const { publicFilter } = require('../../database/row-mappers');
const statuses = ['answered', 'clarification_needed', 'emergency_redirect', 'insufficient_evidence', 'out_of_scope', 'unavailable'];
const keys = ['request_id', 'status', 'answer_blocks', 'citations', 'suggested_category_code', 'suggested_article_id', 'safety_message_code', 'clarification_question', 'corpus_version'];
function clearCurrentIncident(message) {
  const text = message.toLowerCase();
  const has = phrases => phrases.some(p => text.includes(p));
  return has(['đang ', 'ngay bây giờ', 'trước mặt tôi', 'bên cạnh tôi']) && has(['không thở', 'bất tỉnh', 'không đáp ứng', 'chảy máu ồ ạt']) && !has(['đang học', 'tìm hiểu', 'giả sử', 'ví dụ', 'bài học']);
}
function fallback(id, status) {
  return { request_id: id, status, answer_blocks: [], citations: [], suggested_category_code: null, suggested_article_id: null, safety_message_code: null, clarification_question: null, corpus_version: null };
}
function queryInput(b) {
  if (!isObject(b)) throw invalid('request');
  const id = C.uuid(b, 'client_request_id'), message = C.text(b, 'message', 2000, true);
  const age = b.age_group == null ? null : C.value(b, 'age_group', ['ADULT', 'CHILD', 'ALL']);
  const mode = C.value(b, 'context_mode', ['learning', 'unspecified']);
  const context = b.context_messages == null ? [] : C.strings(b, 'context_messages', 4);
  if (context.some(s => s.length > 2000)) throw invalid('context_messages');
  return { request_id: id, message, age_group: age, context_mode: mode, context_messages: context };
}
async function validArticle(db, id, revision, age) {
  if (typeof id !== 'string' || !uuidPattern.test(id)) return false;
  const a = (await db.query(`SELECT a.content_revision,a.age_group FROM articles a JOIN categories c ON c.id=a.category_id WHERE a.id=$1 AND ${publicFilter}`, [id])).rows[0];
  return !!a && (revision == null || Number.isSafeInteger(revision) && revision === a.content_revision) && (a.age_group === 'ALL' || (age !== null && a.age_group === age));
}
async function validCitation(db, c, age) {
  if (!isObject(c) || typeof c.id !== 'string' || !c.id.trim() || typeof c.evidence_id !== 'string' || !c.evidence_id.trim() || typeof c.source_id !== 'string' || !uuidPattern.test(c.source_id) || !Number.isSafeInteger(c.source_revision)) return null;
  const s = (await db.query('SELECT * FROM sources WHERE id=$1 AND is_active=true', [c.source_id])).rows[0];
  if (!s || s.revision !== c.source_revision) return null;
  if (s.media_type === 'PDF' ? !Number.isInteger(c.page_start) || !Number.isInteger(c.page_end) || c.page_start < 1 || c.page_end < c.page_start || c.page_end > s.page_count : c.page_start !== null || c.page_end !== null) return null;
  if (c.article_id != null) {
    if (!Number.isSafeInteger(c.article_revision) || !await validArticle(db, c.article_id, c.article_revision, age)) return null;
    if (!(await db.query('SELECT 1 FROM article_references WHERE article_id=$1 AND source_id=$2', [c.article_id, c.source_id])).rowCount) return null;
  } else if (c.article_revision != null) return null;
  // Titles and identifiers are mapped from DB. Model-supplied URLs/extra fields are discarded.
  return { id: c.id, evidence_id: c.evidence_id, source_id: s.id, source_revision: s.revision, source_title: s.title,
    page_start: c.page_start, page_end: c.page_end, article_id: c.article_id ?? null, article_revision: c.article_revision ?? null };
}
async function validateResponse(db, result, input) {
  const fail = status => fallback(input.request_id, status);
  if (!isObject(result) || keys.some(k => !Object.hasOwn(result, k)) || result.request_id !== input.request_id || !statuses.includes(result.status) || !Array.isArray(result.answer_blocks) || !Array.isArray(result.citations)) return fail('unavailable');
  if (result.answer_blocks.length > 100 || result.citations.length > 100) return fail('unavailable');
  const citations = [], ids = new Set();
  for (const c of result.citations) {
    const mapped = await validCitation(db, c, input.age_group);
    if (!mapped || ids.has(mapped.id)) return fail('insufficient_evidence');
    ids.add(mapped.id); citations.push(mapped);
  }
  const blocks = [];
  if (result.status === 'answered') {
    if (!result.answer_blocks.length || !ids.size) return fail('insufficient_evidence');
    for (const b of result.answer_blocks) {
      if (!isObject(b) || typeof b.text !== 'string' || !b.text.trim() || b.text.length > 20000 || !Array.isArray(b.citation_ids) || !b.citation_ids.length || b.citation_ids.some(id => !ids.has(id))) return fail('insufficient_evidence');
      blocks.push({ text: b.text, citation_ids: b.citation_ids, ...(['paragraph', 'heading', 'steps', 'warning', 'help'].includes(b.kind) ? { kind: b.kind } : {}) });
    }
  } else if (result.answer_blocks.length || citations.length) return fail('unavailable');
  if (result.status === 'clarification_needed' && (typeof result.clarification_question !== 'string' || !result.clarification_question.trim())) return fail('unavailable');
  if (result.status === 'emergency_redirect' && !['CONTACT_HELP', 'OPEN_FIRST_AID_GUIDE'].includes(result.safety_message_code)) return fail('unavailable');
  const output = { ...fail(result.status), answer_blocks: blocks, citations,
    safety_message_code: ['CONTACT_HELP', 'OPEN_FIRST_AID_GUIDE'].includes(result.safety_message_code) ? result.safety_message_code : null,
    clarification_question: typeof result.clarification_question === 'string' ? result.clarification_question : null,
    corpus_version: typeof result.corpus_version === 'string' ? result.corpus_version : null };
  if (await validArticle(db, result.suggested_article_id, null, input.age_group)) output.suggested_article_id = result.suggested_article_id;
  if (typeof result.suggested_category_code === 'string' && /^FA(0[1-9]|1[0-8])$/.test(result.suggested_category_code) && (await db.query('SELECT 1 FROM categories WHERE code=$1 AND is_active=true', [result.suggested_category_code])).rowCount) output.suggested_category_code = result.suggested_category_code;
  if (['extractive', 'grounded'].includes(result.generation_mode)) output.generation_mode = result.generation_mode;
  return output;
}
async function boundedJson(response) {
  let size = 0; const chunks = [];
  for await (const chunk of response.body) {
    size += chunk.length;
    if (size > 1024 * 1024) throw new Error('AI response exceeds limit');
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}
class Assistant {
  constructor(pool, config, transport = fetch) { this.pool = pool; this.config = config; this.transport = transport; this.limiter = new Limiter(config.aiMaxPerMinute, 60000); }
  prepare(body, ip) { const input = queryInput(body); this.limiter.check(ip); return input; }
  async query(input, image = null) {
    const { config } = this;
    if (clearCurrentIncident(input.message)) return { ...fallback(input.request_id, 'emergency_redirect'), safety_message_code: 'CONTACT_HELP' };
    if (!config.aiBaseUrl || !config.aiToken) return fallback(input.request_id, 'unavailable');
    let result;
    try {
      const headers = { 'X-Internal-Token': config.aiToken };
      let body;
      if (image) {
        body = new FormData();
        body.append('request', new Blob([JSON.stringify(input)], { type: 'application/json' }), 'request.json');
        body.append('image', new Blob([image.bytes], { type: image.mime }), image.mime === 'image/png' ? 'image.png' : 'image.jpg');
      } else { body = JSON.stringify(input); headers['Content-Type'] = 'application/json'; }
      const response = await this.transport(config.aiBaseUrl + '/internal/v1/' + (image ? 'query-with-image' : 'query'), {
        method: 'POST', headers, body, redirect: 'error', signal: AbortSignal.timeout(image ? config.aiImageTimeoutMs : config.aiTimeoutMs),
      });
      if (image && [400, 413, 415].includes(response.status)) {
        await response.body?.cancel();
        throw new ApiFailure(response.status, { 400: 'VALIDATION_ERROR', 413: 'IMAGE_TOO_LARGE', 415: 'IMAGE_UNSUPPORTED' }[response.status], 'Yêu cầu ảnh không hợp lệ');
      }
      if (response.status !== 200) { await response.body?.cancel(); return fallback(input.request_id, 'unavailable'); }
      result = await boundedJson(response);
    } catch (error) {
      if (error instanceof ApiFailure) throw error;
      return fallback(input.request_id, 'unavailable');
    }
    // Check all citations against one consistent public-data revision.
    try { return await transaction(this.pool, db => validateResponse(db, result, input), true); }
    catch { return fallback(input.request_id, 'unavailable'); }
  }
}
module.exports = { Assistant, queryInput, clearCurrentIncident, fallback, validateResponse };
