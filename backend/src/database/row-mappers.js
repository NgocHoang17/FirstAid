const pick = (r, keys) => Object.fromEntries(keys.split(' ').map(k => [k, r[k]]));
const category = r => ({ ...pick(r, 'id code name group_code description sort_order is_active'), keywords: r.keywords_json });
const source = r => pick(r, 'id code title publisher publication_year media_type page_count revision original_url is_active rights_note');
const article = r => ({ ...pick(r, 'id category_id slug variant_key title age_group applies_to summary status content_checked checked_at content_revision updated_at'),
  recognition: r.recognition_json, quick_actions: r.quick_actions_json, warnings: r.warnings_json, seek_help: r.seek_help_json });
const step = r => ({ ...pick(r, 'id position title instruction asset_key image_url alt_text image_layout'), images: r.images_json });
const reference = r => pick(r, 'source_id page_start page_end section_key note');
// Shared by public reads, media authorization and the AI gateway.
const publicFilter = `a.status='PUBLISHED' AND a.content_checked=true AND c.is_active=true
  AND NOT EXISTS (SELECT 1 FROM article_references r JOIN sources s ON s.id=r.source_id WHERE r.article_id=a.id AND s.is_active=false)`;
module.exports = { pick, category, source, article, step, reference, publicFilter };
