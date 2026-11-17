"""Compile the reviewed educational content into the shipped public seed."""
import argparse
import hashlib
import json
from pathlib import Path

from validate_reference_content import validate as validate_content

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'mobile/assets/content/offline_snapshot.json'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def build():
    validate_content()
    library = read(ROOT / 'mobile/assets/content/reference_library.json')
    categories = [c for c in library['categories'] if c['is_active']]
    active_ids = {c['id'] for c in categories}
    articles = [a for a in library['articles'] if a['status'] == 'PUBLISHED'
                and a['content_checked'] and a['category_id'] in active_ids]
    used_sources = {r['source_id'] for a in articles for r in a['references']}
    sources = [s for s in library['sources'] if s['is_active'] and s['id'] in used_sources]
    if {s['id'] for s in sources} != used_sources:
        raise ValueError('Public article has unavailable references')
    facilities = []  # Empty compatibility field for the v1 server/client bridge.
    data = {'schema_version': 1, 'region_code': 'VN-DN',
            'app_config': {'locale': 'vi-VN', 'emergency_number': '115'},
            'categories': categories, 'articles': articles, 'sources': sources,
            'facilities': facilities}
    encoded = json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
    data['data_version'] = 'bundled-' + hashlib.sha256(encoded).hexdigest()[:24]
    data['generated_at'] = max(article['checked_at'] for article in articles)
    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = build()
    text = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8') != text:
            raise SystemExit('Shipped data differs from reviewed inputs. Run tools/build_app_data.py.')
    else:
        OUTPUT.write_text(text, encoding='utf-8')
    print(json.dumps({key: len(data[key]) for key in ['categories', 'articles', 'sources', 'facilities']}))


if __name__ == '__main__':
    main()
