"""Load reviewed application data into a migrated PostgreSQL database atomically."""
import argparse
import json
import os
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

import psycopg
from psycopg import sql
from psycopg.types.json import Jsonb

from build_app_data import ROOT, build, read


def database_records():
    seed = build()
    library = read(ROOT / 'mobile/assets/content/reference_library.json')
    records = {name: [] for name in ['categories', 'sources', 'articles', 'article_steps', 'article_references', 'facilities']}
    for category in library['categories']:
        row = {key: category.get(key) for key in ['id', 'code', 'name', 'group_code', 'description', 'sort_order', 'is_active', 'coverage_note', 'audience_policy']}
        row['keywords_json'] = Jsonb(category['keywords'])
        row['pdf_evidence_json'] = Jsonb(category.get('pdf_evidence', {}))
        records['categories'].append(row)
    source_fields = ['id', 'code', 'title', 'publisher', 'publication_year', 'media_type',
                     'page_count', 'revision', 'original_url', 'accessed_at', 'is_active', 'rights_note']
    records['sources'] = [{key: source.get(key) for key in source_fields} for source in library['sources']]
    article_fields = ['id', 'category_id', 'slug', 'variant_key', 'title', 'age_group', 'applies_to',
                      'summary', 'status', 'content_checked', 'checked_at', 'content_revision', 'updated_at']
    for article in seed['articles']:
        row = {key: article[key] for key in article_fields}
        for key in ['recognition', 'quick_actions', 'warnings', 'seek_help']:
            row[key + '_json'] = Jsonb(article[key])
        records['articles'].append(row)
        for step in article['steps']:
            records['article_steps'].append({**step, 'article_id': article['id']})
        for position, reference in enumerate(article['references'], start=1):
            identifier = uuid5(NAMESPACE_URL, f"https://firstaid.local/articles/{article['id']}/references/{position}")
            records['article_references'].append({'id': str(identifier), 'article_id': article['id'],
                                                  'position': position, **reference})
    return records


def row_matches(connection, table, row):
    conditions = [sql.SQL('{} IS NOT DISTINCT FROM %s').format(sql.Identifier(key)) for key in row]
    query = sql.SQL('SELECT count(*) FROM {} WHERE {}').format(
        sql.Identifier(table), sql.SQL(' AND ').join(conditions))
    return connection.execute(query, list(row.values())).fetchone()[0] == 1


def insert_row(connection, table, row, *, update=False):
    columns = list(row)
    query = sql.SQL('INSERT INTO {} ({}) VALUES ({})').format(
        sql.Identifier(table), sql.SQL(',').join(map(sql.Identifier, columns)),
        sql.SQL(',').join(sql.Placeholder() for _ in columns))
    if update:
        assignments = [sql.SQL('{}=EXCLUDED.{}').format(sql.Identifier(key), sql.Identifier(key))
                       for key in columns if key != 'id']
        query += sql.SQL(' ON CONFLICT(id) DO UPDATE SET {}').format(sql.SQL(',').join(assignments))
    connection.execute(query, list(row.values()))


def import_data(dsn):
    records = database_records()
    with psycopg.connect(dsn) as connection:
        connection.execute('SELECT pg_advisory_xact_lock(20261117, 1)')
        connection.execute('LOCK TABLE categories,sources,articles,article_steps,article_references,facilities IN SHARE ROW EXCLUSIVE MODE')
        existing = connection.execute('SELECT count(*) FROM articles').fetchone()[0]
        if existing:
            for table, rows in records.items():
                if any(not row_matches(connection, table, row) for row in rows):
                    return {'status': 'preserved_existing_data', 'changed_table': table,
                            'articles': existing}
            return {'status': 'unchanged', **{table: len(rows) for table, rows in records.items()}}
        for table, rows in records.items():
            for row in rows:
                insert_row(connection, table, row, update=table in ['categories', 'sources'])
        connection.execute('UPDATE public_data_state SET data_version=%s,updated_at=now() WHERE id=1',
                           (str(uuid5(NAMESPACE_URL, build()['data_version'])),))
        # Any failed insert or evidence validation above rolls back the whole import.
    return {'status': 'imported', **{table: len(rows) for table, rows in records.items()}}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dsn-env', default='FIRSTAID_DATABASE_DSN')
    args = parser.parse_args()
    dsn = os.environ.get(args.dsn_env)
    if not dsn:
        raise SystemExit(f'Set {args.dsn_env} in the environment.')
    print(json.dumps(import_data(dsn)))


if __name__ == '__main__':
    main()
