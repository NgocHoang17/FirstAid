const { transaction } = require('./pool');
const { Articles } = require('../modules/articles/article.service');

async function insert(db, table, record, update = false) {
  // Table/column identifiers are exclusively from the hardcoded mappings below.
  const keys = Object.keys(record);
  const values = Object.values(record).map(v => Array.isArray(v) || v && typeof v === 'object' ? JSON.stringify(v) : v);
  const suffix = update ? ' ON CONFLICT(id) DO UPDATE SET ' + keys.filter(k => k !== 'id').map(k => `${k}=EXCLUDED.${k}`).join(',') : '';
  await db.query(`INSERT INTO ${table}(${keys.join(',')}) VALUES(${keys.map((_, i) => '$' + (i + 1)).join(',')})${suffix}`, values);
}


function pick(b, fields) { return Object.fromEntries(fields.split(' ').map(k => [k, b[k] ?? null])); }
async function seed(pool, config, library, snapshot) {
  if (!Array.isArray(library.categories) || !Array.isArray(library.sources) || !Array.isArray(snapshot.articles)) throw new Error('Invalid seed files');
  return transaction(pool, async db => {
    await db.query('SELECT pg_advisory_xact_lock(20261117, 1)');
    await db.query('LOCK TABLE categories,sources,articles,article_steps,article_references IN SHARE ROW EXCLUSIVE MODE');
    const count = (await db.query('SELECT count(*) FROM articles')).rows[0].count;
    if (count) return { status: 'preserved_existing_data', articles: count };
    for (const c of library.categories) await insert(db, 'categories', {
      ...pick(c, 'id code name group_code description sort_order is_active coverage_note audience_policy'),
      keywords_json: c.keywords, pdf_evidence_json: c.pdf_evidence || {},
    }, true);
    for (const s of library.sources) await insert(db, 'sources', pick(s, 'id code title publisher publication_year media_type page_count revision original_url accessed_at is_active rights_note'), true);
    const articles = new Articles(db, config);
    for (const a of snapshot.articles) {
      if (a.status !== 'PUBLISHED' || !a.content_checked || !a.checked_at || !Number.isSafeInteger(a.content_revision) || a.content_revision < 1) throw new Error('Seed article must be checked and published');
      await insert(db, 'articles', { ...pick(a, 'id category_id slug variant_key title age_group applies_to summary content_checked checked_at content_revision updated_at'),
        status: 'DRAFT', recognition_json: a.recognition, quick_actions_json: a.quick_actions, warnings_json: a.warnings, seek_help_json: a.seek_help });
      await articles.saveSteps(a.id, a.steps);
      await articles.saveReferences(a.id, a.references);
      await articles.publish(a.id, a.content_revision);
    }
    return { status: 'imported', articles: snapshot.articles.length, categories: library.categories.length, sources: library.sources.length };
  });
}

module.exports = { seed };
