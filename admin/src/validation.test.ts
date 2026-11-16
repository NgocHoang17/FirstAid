import { describe, expect, it } from 'vitest';
import library from '../../mobile/assets/content/reference_library.json';
import { blankEntity, type Article, type Category, type Source } from './models';
import { validate } from './validation';

const categories = library.categories as Category[];
const sources = library.sources as Source[];
describe('editor validation', () => {
  it('accepts all 24 checked articles without inventing different age or source rules', () => {
    expect(library.articles).toHaveLength(24);
    for (const article of library.articles) expect(validate('articles', article as Article, categories, sources, true), article.title).toEqual([]);
  });
  it('allows partial drafts but prevents publishing missing sections or confirmation', () => {
    const a = { ...blankEntity('articles'), title: 'Draft', category_id: categories[0].id, slug: 'draft', variant_key: 'draft' };
    expect(validate('articles', a)).toEqual([]);
    expect(validate('articles', a, categories, sources, true).map(e => e.field)).toEqual(expect.arrayContaining(['applies_to', 'summary', 'steps', 'references', 'content_checked']));
  });
  it('enforces PDF bounds and null web pages, active sources and image descriptions', () => {
    const a = structuredClone(library.articles[0]) as Article;
    const pdf = sources.find(s => s.media_type === 'PDF')!; const web = sources.find(s => s.media_type === 'WEB')!;
    a.references = [{ source_id: pdf.id, page_start: 1, page_end: pdf.page_count! + 1, section_key: 'all', note: '' }];
    expect(validate('articles', a, categories, sources)).toEqual(expect.arrayContaining([expect.objectContaining({ field: 'references.0.page_start' })]));
    a.references[0] = { ...a.references[0], source_id: web.id, page_start: null, page_end: null };
    expect(validate('articles', a, categories, sources, true)).toEqual([]);
    a.steps[0].image_url = 'javascript:alert(1)'; a.steps[0].alt_text = null;
    expect(validate('articles', a, categories, sources).map(e => e.field)).toEqual(expect.arrayContaining(['steps.0.image_url', 'steps.0.alt_text']));
    expect(validate('articles', a, categories, sources.map(s => ({ ...s, is_active: false })), true).map(e => e.field)).toContain('references.0.source_id');
  });
  it('rejects unverified active facilities and invalid coordinates; UNKNOWN is valid', () => {
    const f = { ...blankEntity('facilities'), name: 'Fixture — not real', address: 'Demo', region_code: 'VN-TEST', is_active: true };
    expect(validate('facilities', f).map(e => e.field)).toEqual(expect.arrayContaining(['phone', 'latitude', 'verification_note', 'verified_at']));
    const verified = { ...f, phone: '02361234567', latitude: 16, longitude: 108, verification_note: 'Fixture', verified_at: '2026-01-01T00:00:00Z' };
    expect(validate('facilities', verified)).toEqual([]);
    expect(validate('facilities', { ...verified, latitude: 100 }).map(e => e.field)).toContain('latitude');
    expect(validate('facilities', { ...verified, phone: '115' }).map(e => e.field)).toContain('phone');
  });
});
