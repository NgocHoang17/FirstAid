"""Validate the bundled course reference library. This is not clinical approval."""
import json
from datetime import datetime
from pathlib import Path
from uuid import UUID

ROOT = Path(__file__).resolve().parents[1]

def validate():
    data = json.loads((ROOT / 'mobile/assets/content/reference_library.json').read_text(encoding='utf-8'))
    review = json.loads((ROOT / 'mobile/assets/content/editorial_review.json').read_text(encoding='utf-8'))
    assert data['kind'] == 'reference_library'
    assert len(data['articles']) == 24 and len(data['categories']) == 18
    sources = {s['id']: s for s in data['sources']}
    assert len(sources) == len(data['sources'])
    checked = {a['article_id']: a for a in review['articles']}
    assert len(checked) == 24 and review['clinical_expert_review'] is False
    assert review['catalogue_version'] == data['data_version']
    article_ids, step_ids, assets = set(), set(), set()
    for article in data['articles']:
        UUID(article['id'])
        assert article['id'] not in article_ids
        article_ids.add(article['id'])
        assert article['status'] == 'PUBLISHED' and article['content_checked'] is True
        datetime.fromisoformat(article['checked_at'].replace('Z', '+00:00'))
        audit = checked[article['id']]
        assert audit['clinical_expert_review'] is False and audit['checker'] and audit['method'] == 'source_comparison_for_course_project'
        for field in ['applies_to', 'summary', 'recognition', 'quick_actions', 'warnings', 'seek_help']:
            assert article[field], (article['variant_key'], field)
        assert article['age_group'] in {'ALL', 'ADULT', 'CHILD'}
        for position, step in enumerate(article['steps'], 1):
            UUID(step['id'])
            assert step['id'] not in step_ids and step['position'] == position
            step_ids.add(step['id'])
            assert step['instruction'] and step['title'] and step['alt_text']
            asset = (ROOT / 'mobile' / step['asset_key']).resolve()
            assert asset.is_relative_to((ROOT / 'mobile/assets/illustrations').resolve()) and asset.is_file()
            diagram = json.loads(asset.read_text(encoding='utf-8'))
            assert diagram['schema_version'] == 1 and diagram['clinical_pose'] is False
            assert diagram['caption'] == step['alt_text'] and diagram['authorship'].startswith('Original FirstAid')
            assets.add(asset)
        for reference in article['references']:
            source = sources[reference['source_id']]
            assert source['code'] in audit['sources']
            if source['media_type'] == 'PDF':
                assert 1 <= reference['page_start'] <= reference['page_end'] <= source['page_count']
            else:
                assert source['original_url'].startswith('https://')
                assert reference['page_start'] is None and reference['page_end'] is None
    for category in data['categories']:
        expected = {a['id'] for a in data['articles'] if a['category_id'] == category['id']}
        assert expected and expected == set(category['article_ids'])
    print(f"PASS: {len(article_ids)} source-checked course articles, 18 categories, {len(sources)} sources, {len(assets)} offline diagrams")
    print('Clinical expert review: not claimed. Content check: documented source comparison for a course project.')
    return data

if __name__ == '__main__':
    validate()
