const { randomUUID } = require('node:crypto');
const { checks: C, invalid, notFound, inUse } = require('../../shared/api');
const rows = require('../../database/row-mappers');

class Catalog {
  constructor(db) { this.db = db; }
  async bump() { await this.db.query('UPDATE public_data_state SET data_version=$1,updated_at=now() WHERE id=1', [randomUUID()]); }
  async categories(admin) {
    return (await this.db.query(`SELECT * FROM categories ${admin ? '' : 'WHERE is_active=true'} ORDER BY sort_order,code`)).rows.map(rows.category);
  }
  async sources(admin) {
    return (await this.db.query(`SELECT * FROM sources ${admin ? '' : 'WHERE is_active=true'} ORDER BY code`)).rows.map(rows.source);
  }
  async category(id, admin = true, lock = false) {
    const r = (await this.db.query(`SELECT * FROM categories WHERE id=$1 ${admin ? '' : 'AND is_active=true'} ${lock ? 'FOR UPDATE' : ''}`, [id])).rows[0];
    if (!r) throw notFound();
    return rows.category(r);
  }
  async source(id, admin = true, lock = false) {
    const r = (await this.db.query(`SELECT * FROM sources WHERE id=$1 ${admin ? '' : 'AND is_active=true'} ${lock ? 'FOR UPDATE' : ''}`, [id])).rows[0];
    if (!r) throw notFound();
    return rows.source(r);
  }
  async exists(sql, params) { return (await this.db.query(sql, params)).rowCount > 0; }
  async saveCategory(id, b) {
    const code = C.text(b, 'code', 4, true);
    if (!/^FA(0[1-9]|1[0-8])$/.test(code)) throw invalid('code', 'Mã danh mục trong phạm vi FA01–FA18');
    const name = C.text(b, 'name', 200, true), group = C.value(b, 'group_code', ['CIRCULATION', 'TRAUMA', 'ENVIRONMENT', 'OTHER']);
    const description = C.text(b, 'description', 4000) || '', keywords = C.strings(b, 'keywords', 100);
    const sort = C.integer(b, 'sort_order', 0, 10000, 0), active = C.bool(b, 'is_active', true);
    if (id) {
      const old = await this.category(id, true, true);
      if (old.code !== code && (/^FA(0[1-9]|1[0-8])$/.test(old.code) || await this.exists('SELECT 1 FROM articles WHERE category_id=$1', [id]))) throw invalid('code', 'Mã danh mục chính thức hoặc đã có bài phải giữ ổn định');
      if (!active && await this.exists("SELECT 1 FROM articles WHERE category_id=$1 AND status='PUBLISHED'", [id])) throw inUse();
      await this.db.query('UPDATE categories SET code=$1,name=$2,group_code=$3,description=$4,keywords_json=$5,sort_order=$6,is_active=$7 WHERE id=$8', [code, name, group, description, JSON.stringify(keywords), sort, active, id]);
    } else {
      id = randomUUID();
      await this.db.query('INSERT INTO categories(id,code,name,group_code,description,keywords_json,sort_order,is_active) VALUES($1,$2,$3,$4,$5,$6,$7,$8)', [id, code, name, group, description, JSON.stringify(keywords), sort, active]);
    }
    await this.bump(); return this.category(id);
  }
  async deleteCategory(id) {
    await this.category(id, true, true);
    if (await this.exists('SELECT 1 FROM articles WHERE category_id=$1', [id])) throw inUse();
    await this.db.query('DELETE FROM categories WHERE id=$1', [id]); await this.bump();
  }
  async saveSource(id, b) {
    const code = C.text(b, 'code', 80, true), title = C.text(b, 'title', 300, true), publisher = C.text(b, 'publisher', 500, true);
    const media = C.value(b, 'media_type', ['PDF', 'WEB']), year = C.integer(b, 'publication_year', 1000, 9999), pages = C.integer(b, 'page_count', 1, 100000);
    const url = C.https(C.text(b, 'original_url', 2000), 'original_url'), rights = C.text(b, 'rights_note', 4000), active = C.bool(b, 'is_active', true);
    if (media === 'PDF' && pages === null) throw invalid('page_count', 'PDF cần số trang');
    if (media === 'WEB' && (pages !== null || !url)) throw invalid('media_type', 'WEB cần URL HTTPS và không có số trang');
    let revision = 1;
    if (id) {
      const old = await this.source(id, true, true);
      if (old.code !== code && await this.exists('SELECT 1 FROM article_references WHERE source_id=$1', [id])) throw invalid('code', 'Mã nguồn đã được trích dẫn phải giữ ổn định');
      if (!active && await this.exists("SELECT 1 FROM article_references r JOIN articles a ON a.id=r.article_id WHERE r.source_id=$1 AND a.status='PUBLISHED'", [id])) throw inUse();
      if (media === 'WEB' && await this.exists('SELECT 1 FROM article_references WHERE source_id=$1 AND (page_start IS NOT NULL OR page_end IS NOT NULL)', [id])) throw inUse();
      if (media === 'PDF' && await this.exists('SELECT 1 FROM article_references WHERE source_id=$1 AND (page_start IS NULL OR page_end IS NULL OR page_end>$2)', [id, pages])) throw inUse();
      const updated = { code, title, publisher, publication_year: year, media_type: media, page_count: pages, original_url: url };
      revision = old.revision + (Object.entries(updated).some(([k, v]) => old[k] !== v) ? 1 : 0);
      await this.db.query('UPDATE sources SET code=$1,title=$2,publisher=$3,publication_year=$4,media_type=$5,page_count=$6,revision=$7,original_url=$8,is_active=$9,rights_note=$10 WHERE id=$11', [code, title, publisher, year, media, pages, revision, url, active, rights, id]);
    } else {
      id = randomUUID();
      await this.db.query('INSERT INTO sources(id,code,title,publisher,publication_year,media_type,page_count,revision,original_url,is_active,rights_note) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)', [id, code, title, publisher, year, media, pages, revision, url, active, rights]);
    }
    await this.bump(); return this.source(id);
  }
  async deleteSource(id) {
    await this.source(id, true, true);
    if (await this.exists('SELECT 1 FROM article_references WHERE source_id=$1', [id])) throw inUse();
    await this.db.query('DELETE FROM sources WHERE id=$1', [id]); await this.bump();
  }
}
module.exports = { Catalog };
