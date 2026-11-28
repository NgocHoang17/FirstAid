const { createHash } = require('node:crypto');
const { checks: C, invalid, ApiFailure, unavailable } = require('../../shared/api');
const { Catalog } = require('../catalog/catalog.service');
const { Articles } = require('../articles/article.service');
const { source, publicFilter } = require('../../database/row-mappers');
async function snapshot(db, config, query, ifNoneMatch) {
  const schema = query.schema_version == null ? '1' : query.schema_version;
  if (!['1', '2'].includes(schema)) throw invalid('schema_version');
  if (!config.emergencyNumber || (schema === '1' && !config.region)) throw unavailable();
  let region = null;
  if (schema === '1') {
    region = C.text(query, 'region_code', 40, true);
    if (region !== config.region) throw invalid('region_code', 'Vùng chưa được cấu hình công khai');
  }
  const state = (await db.query('SELECT data_version,updated_at FROM public_data_state WHERE id=1')).rows[0];
  if (!state) throw unavailable();
  // v1 retains its UUID token; v2 uses a deterministic, separate opaque token.
  const version = schema === '1' ? state.data_version : 'v2-' + createHash('sha256').update(state.data_version).digest('hex').slice(0, 32);
  const etag = '"' + version + '"';
  if (ifNoneMatch?.split(',').some(t => t.trim().replace(/^W\//, '') === etag || t.trim() === '*')) return { etag, payload: null };
  const catalog = new Catalog(db), articles = new Articles(db, config);
  const categories = await catalog.categories(false), summaries = await articles.list({});
  const fullArticles = [];
  for (const summary of summaries) fullArticles.push(await articles.get(summary.id));
  const sources = (await db.query(`SELECT s.* FROM sources s WHERE s.is_active=true AND EXISTS (
    SELECT 1 FROM article_references r JOIN articles a ON a.id=r.article_id JOIN categories c ON c.id=a.category_id
    WHERE r.source_id=s.id AND ${publicFilter}) ORDER BY s.code`)).rows.map(source);
  if (categories.length > 30 || fullArticles.length > 500 || sources.length > 100) throw new ApiFailure(503, 'SERVICE_UNAVAILABLE', 'Snapshot vượt giới hạn contract');
  return { etag, payload: { schema_version: Number(schema), data_version: version, generated_at: state.updated_at,
    ...(schema === '1' ? { region_code: region, facilities: [] } : {}),
    app_config: { locale: config.locale, emergency_number: config.emergencyNumber }, categories, articles: fullArticles, sources } };
}
module.exports = { snapshot };
