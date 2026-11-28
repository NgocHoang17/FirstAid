const { randomUUID } = require('node:crypto');
const { checks: C, invalid, notFound, conflict, ApiFailure } = require('../../shared/api');
const rows = require('../../database/row-mappers');
const { Catalog } = require('../catalog/catalog.service');

class Articles {
  constructor(db, config) { this.db = db; this.config = config; this.catalog = new Catalog(db); }
  async get(id, admin = false, lock = false) {
    const r = (await this.db.query(`SELECT a.* FROM articles a JOIN categories c ON c.id=a.category_id WHERE a.id=$1 ${admin ? '' : `AND ${rows.publicFilter}`} ${lock ? 'FOR UPDATE OF a' : ''}`, [id])).rows[0];
    if (!r) throw notFound();
    const a = rows.article(r);
    a.steps = (await this.db.query('SELECT * FROM article_steps WHERE article_id=$1 ORDER BY position', [id])).rows.map(rows.step);
    a.references = (await this.db.query('SELECT * FROM article_references WHERE article_id=$1 ORDER BY position', [id])).rows.map(rows.reference);
    return a;
  }
  filter({ category, age, q, status }, admin) {
    if (age != null && !['ADULT', 'CHILD', 'ALL'].includes(age)) throw invalid('age_group');
    if (status != null && !['DRAFT', 'PUBLISHED'].includes(status)) throw invalid('status');
    const parts = [admin ? 'true' : rows.publicFilter], params = [];
    const param = v => { params.push(v); return '$' + params.length; };
    if (category) parts.push(`a.category_id=${param(category)}`);
    if (age) parts.push(`a.age_group IN (${param(age)},'ALL')`);
    if (status && admin) parts.push(`a.status=${param(status)}`);
    if (q?.trim()) {
      const needle = param('%' + q.trim().toLowerCase().replace(/[\\%_]/g, '\\$&') + '%');
      parts.push(`(lower(a.title) LIKE ${needle} OR lower(a.summary) LIKE ${needle} OR lower(c.name) LIKE ${needle})`);
    }
    return { where: parts.join(' AND '), params };
  }
  async list(filters, admin = false, page = 1, size = 20) {
    const { where, params } = this.filter(filters, admin);
    const result = await this.db.query(`SELECT a.* FROM articles a JOIN categories c ON c.id=a.category_id WHERE ${where} ORDER BY c.sort_order,a.title,a.id LIMIT $${params.length + 1} OFFSET $${params.length + 2}`, [...params, admin ? size : 501, admin ? (page - 1) * size : 0]);
    if (!admin && result.rows.length > 500) throw new ApiFailure(503, 'SERVICE_UNAVAILABLE', 'Danh sách vượt giới hạn contract');
    const keys = 'id category_id slug variant_key title age_group summary content_revision updated_at' + (admin ? ' status content_checked' : '');
    return result.rows.map(r => rows.pick(r, keys));
  }
  async count(filters) {
    const { where, params } = this.filter(filters, true);
    return (await this.db.query(`SELECT count(*) FROM articles a JOIN categories c ON c.id=a.category_id WHERE ${where}`, params)).rows[0].count;
  }
  async save(id, b) {
    const category = C.uuid(b, 'category_id'), slug = C.text(b, 'slug', 200, true), variant = C.text(b, 'variant_key', 100, true);
    const title = C.text(b, 'title', 200, true), age = C.value(b, 'age_group', ['ADULT', 'CHILD', 'ALL']);
    const applies = C.text(b, 'applies_to', 4000) || '', summary = C.text(b, 'summary', 1000) || '';
    const arrays = ['recognition', 'quick_actions', 'warnings', 'seek_help'].map(k => JSON.stringify(C.strings(b, k, 100)));
    const steps = C.objects(b, 'steps', 50), refs = C.objects(b, 'references', 100);
    let checked = C.bool(b, 'content_checked'), old = null;
    if (id) {
      old = await this.get(id, true, true);
      if (old.category_id !== category || old.variant_key !== variant) throw invalid('variant_key', 'Danh mục và mã biến thể phải giữ ổn định');
      if (old.content_revision !== C.revision(b)) throw conflict();
      if (old.status === 'PUBLISHED') checked = false;
    } else id = randomUUID();
    // SHARE locks serialize publication/reference edits with category/source deactivation.
    if (!(await this.db.query('SELECT id FROM categories WHERE id=$1 FOR SHARE', [category])).rowCount) throw notFound();
    const checkedAt = checked ? new Date() : null;
    const params = [category, slug, variant, title, age, applies, summary, ...arrays, checked, checkedAt, id];
    if (old) {
      await this.db.query(`UPDATE articles SET category_id=$1,slug=$2,variant_key=$3,title=$4,age_group=$5,applies_to=$6,summary=$7,
        recognition_json=$8,quick_actions_json=$9,warnings_json=$10,seek_help_json=$11,status='DRAFT',content_checked=$12,
        checked_at=$13,content_revision=content_revision+1,updated_at=now() WHERE id=$14`, params);
      await this.db.query('DELETE FROM article_steps WHERE article_id=$1', [id]);
      await this.db.query('DELETE FROM article_references WHERE article_id=$1', [id]);
    } else {
      await this.db.query(`INSERT INTO articles(category_id,slug,variant_key,title,age_group,applies_to,summary,recognition_json,
        quick_actions_json,warnings_json,seek_help_json,content_checked,checked_at,id) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`, params);
    }
    await this.saveSteps(id, steps);
    await this.saveReferences(id, refs);
    if (old?.status === 'PUBLISHED') await this.catalog.bump();
    return this.get(id, true);
  }
  async saveSteps(articleId, steps) {
    const ids = new Set();
    for (const [i, s] of steps.entries()) {
      if (C.integer(s, 'position', 1, 50) !== i + 1) throw invalid('steps', 'Vị trí bước phải liên tiếp từ 1');
      const id = s.id == null ? randomUUID() : C.uuid(s, 'id');
      if (ids.has(id)) throw invalid('steps', 'ID bước bị trùng');
      ids.add(id);
      const title = C.text(s, 'title', 200, true), instruction = C.text(s, 'instruction', 4000, true);
      const asset = C.text(s, 'asset_key', 200), image = C.https(C.text(s, 'image_url', 2000), 'image_url'), alt = C.text(s, 'alt_text', 1000);
      if (asset && !this.config.assetKeys.has(asset)) throw invalid('asset_key', 'Asset không nằm trong ứng dụng');
      if ((asset || image) && !alt) throw invalid('alt_text', 'Ảnh cần mô tả');
      const layout = s.image_layout == null ? 'stacked' : C.value(s, 'image_layout', ['stacked', 'grid', 'carousel']);
      const images = [], mediaIds = new Set();
      for (const picture of (s.images == null ? [] : C.objects(s, 'images', 6))) {
        const mediaId = C.uuid(picture, 'media_id');
        if (mediaIds.has(mediaId) || !(await this.db.query('SELECT 1 FROM media_assets WHERE id=$1', [mediaId])).rowCount) throw invalid('images', 'Ảnh không tồn tại hoặc bị trùng');
        mediaIds.add(mediaId);
        images.push({ media_id: mediaId, url: '/api/v1/media/' + mediaId, alt_text: C.text(picture, 'alt_text', 1000, true), caption: C.text(picture, 'caption', 1000) || '' });
      }
      await this.db.query(`INSERT INTO article_steps(id,article_id,position,title,instruction,asset_key,image_url,alt_text,image_layout,images_json)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`, [id, articleId, i + 1, title, instruction, asset, image, alt, layout, JSON.stringify(images)]);
    }
  }
  async saveReferences(articleId, refs) {
    // Acquire source locks in a stable order to avoid deadlocks across editors.
    const sourceIds = [...new Set(refs.map(r => C.uuid(r, 'source_id')))].sort();
    await this.db.query('SELECT id FROM sources WHERE id=ANY($1::uuid[]) ORDER BY id FOR SHARE', [sourceIds]);
    for (const [i, r] of refs.entries()) {
      const sourceId = C.uuid(r, 'source_id'), source = await this.catalog.source(sourceId);
      const start = C.integer(r, 'page_start', 1, 100000), end = C.integer(r, 'page_end', 1, 100000);
      if (source.media_type === 'PDF' ? start === null || end === null || end < start || end > source.page_count : start !== null || end !== null) throw invalid('references', 'Trang nguồn không hợp lệ');
      await this.db.query(`INSERT INTO article_references(id,article_id,source_id,position,page_start,page_end,section_key,note)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, [randomUUID(), articleId, sourceId, i + 1, start, end, C.text(r, 'section_key', 80) || 'all', C.text(r, 'note', 4000)]);
    }
  }
  async publish(id, revision) {
    const a = await this.get(id, true, true);
    if (a.content_revision !== revision) throw conflict();
    if (a.status !== 'DRAFT') throw conflict();
    const notReady = () => { throw new ApiFailure(422, 'CONTENT_NOT_READY', 'Bài chưa đủ nội dung hoặc nguồn để công bố'); };
    if (!a.content_checked || !a.checked_at || !a.applies_to.trim() || !a.summary.trim() || ['recognition', 'quick_actions', 'steps', 'warnings', 'seek_help', 'references'].some(k => !a[k].length)) notReady();
    await this.db.query('SELECT id FROM categories WHERE id=$1 FOR SHARE', [a.category_id]);
    if (!(await this.catalog.category(a.category_id)).is_active) notReady();
    const sourceIds = [...new Set(a.references.map(r => r.source_id))].sort();
    await this.db.query('SELECT id FROM sources WHERE id=ANY($1::uuid[]) ORDER BY id FOR SHARE', [sourceIds]);
    for (const ref of a.references) {
      const source = await this.catalog.source(ref.source_id);
      if (!source.is_active || (source.media_type === 'PDF' ? ref.page_start === null || ref.page_end < ref.page_start || ref.page_end > source.page_count : ref.page_start !== null || ref.page_end !== null)) notReady();
    }
    await this.db.query("UPDATE articles SET status='PUBLISHED',updated_at=now() WHERE id=$1", [id]);
    await this.catalog.bump(); return this.get(id, true);
  }
  async unpublish(id, revision) {
    const a = await this.get(id, true, true);
    if (a.content_revision !== revision) throw conflict();
    if (a.status === 'PUBLISHED') {
      await this.db.query("UPDATE articles SET status='DRAFT',updated_at=now() WHERE id=$1", [id]);
      await this.catalog.bump();
    }
    return this.get(id, true);
  }
  async delete(id) {
    const a = await this.get(id, true, true);
    await this.db.query('DELETE FROM articles WHERE id=$1', [id]);
    if (a.status === 'PUBLISHED') await this.catalog.bump();
  }
}
module.exports = { Articles };
