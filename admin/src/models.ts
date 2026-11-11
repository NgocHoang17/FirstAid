export type Resource = 'articles' | 'categories' | 'sources' | 'facilities';
export type Status = 'DRAFT' | 'PUBLISHED';
export type AgeGroup = 'ADULT' | 'CHILD' | 'ALL';
export interface Category {
  id: string; code: string; name: string; group_code: 'CIRCULATION' | 'TRAUMA' | 'ENVIRONMENT' | 'OTHER';
  description: string; keywords: string[]; sort_order: number; is_active: boolean;
}
export interface Source {
  id: string; code: string; title: string; publisher: string; publication_year: number | null;
  media_type: 'PDF' | 'WEB'; page_count: number | null; revision: number;
  original_url: string | null; is_active: boolean; rights_note: string;
}
export interface Step {
  id?: string; position: number; title: string; instruction: string;
  asset_key: string | null; image_url: string | null; alt_text: string | null;
}
export interface Reference {
  source_id: string; page_start: number | null; page_end: number | null; section_key: string; note: string;
}
export interface Article {
  id: string; category_id: string; slug: string; variant_key: string; title: string; age_group: AgeGroup;
  applies_to: string; summary: string; recognition: string[]; quick_actions: string[];
  steps: Step[]; warnings: string[]; seek_help: string[]; references: Reference[];
  status: Status; content_checked: boolean; checked_at: string | null; content_revision: number; updated_at: string;
}
export interface Facility {
  id: string; name: string; region_code: string; address: string; phone: string | null;
  latitude: number | null; longitude: number | null; emergency_24h: 'YES' | 'NO' | 'UNKNOWN';
  verification_note: string; verified_at: string | null; is_active: boolean;
}
export interface Entities { articles: Article; categories: Category; sources: Source; facilities: Facility }
export type Entity = Entities[Resource];
export interface Admin { id: string; username: string; role: 'ADMIN' }
export interface Page<T> { items: T[]; page: number; page_size: number; total: number }
export interface FieldError { field: string; message: string }
export const ageLabels: Record<AgeGroup, string> = { ALL: 'Người lớn & trẻ em', ADULT: 'Người lớn', CHILD: 'Trẻ em' };
export const resourceLabels: Record<Resource, string> = { articles: 'Bài sơ cứu', categories: 'Danh mục', sources: 'Nguồn tài liệu', facilities: 'Cơ sở y tế' };
export const normalize = (text: string) => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
// Preserve spaces while typing optional descriptions; blank input still maps to null.
export const nullable = (text: string) => text.trim() ? text : null;
export function blankEntity<R extends Resource>(resource: R): Entities[R] {
  const values: { [K in Resource]: Entities[K] } = {
    articles: { id: '', title: '', category_id: '', slug: '', variant_key: '', age_group: 'ALL', applies_to: '', summary: '', recognition: [], quick_actions: [], steps: [], warnings: [], seek_help: [], references: [], status: 'DRAFT', content_checked: false, checked_at: null, content_revision: 0, updated_at: '' },
    categories: { id: '', code: '', name: '', group_code: 'OTHER', description: '', keywords: [], sort_order: 1, is_active: true },
    sources: { id: '', code: '', title: '', publisher: '', publication_year: null, page_count: null, media_type: 'PDF', revision: 1, original_url: null, is_active: true, rights_note: '' },
    facilities: { id: '', name: '', region_code: '', address: '', phone: null, latitude: null, longitude: null, emergency_24h: 'UNKNOWN', verification_note: '', verified_at: null, is_active: false },
  };
  return structuredClone(values[resource]);
}
