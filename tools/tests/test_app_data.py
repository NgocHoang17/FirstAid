import os
import sys
from pathlib import Path
from uuid import uuid4

import psycopg
from psycopg import sql
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import import_app_data
from build_app_data import ROOT, OUTPUT, build, read


def test_shipped_snapshot_matches_reviewed_sources():
    snapshot = build()
    assert read(OUTPUT) == snapshot
    assert len(snapshot['articles']) == 24
    assert len(snapshot['sources']) == 17
    assert snapshot['facilities'] == []
    assert all(a['status'] == 'PUBLISHED' and a['content_checked'] for a in snapshot['articles'])


@pytest.fixture
def database():
    dsn = os.getenv('FIRSTAID_TEST_DATABASE_DSN')
    if not dsn:
        pytest.skip('Set FIRSTAID_TEST_DATABASE_DSN to a local PostgreSQL instance')
    name = 'firstaid_import_test_' + uuid4().hex
    params = psycopg.conninfo.conninfo_to_dict(dsn)
    with psycopg.connect(dsn, autocommit=True) as admin:
        admin.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(name)))
    test_dsn = psycopg.conninfo.make_conninfo(**{**params, 'dbname': name})
    try:
        with psycopg.connect(test_dsn) as connection:
            migrations = ROOT / 'backend/db/migrations'
            connection.execute((migrations / 'V1__schema.sql').read_text(encoding='utf-8'))
            connection.execute((migrations / 'V2__reference_metadata.sql').read_text(encoding='utf-8'))
        yield test_dsn
    finally:
        with psycopg.connect(dsn, autocommit=True) as admin:
            admin.execute(sql.SQL('DROP DATABASE {}').format(sql.Identifier(name)))


def test_import_rolls_back_on_partial_failure(database, monkeypatch):
    original = import_app_data.database_records
    def invalid_records():
        records = original()
        records['article_steps'][0]['position'] = -1
        return records
    monkeypatch.setattr(import_app_data, 'database_records', invalid_records)
    with pytest.raises(psycopg.errors.CheckViolation):
        import_app_data.import_data(database)
    with psycopg.connect(database) as connection:
        assert connection.execute('SELECT count(*) FROM articles').fetchone()[0] == 0
        assert connection.execute('SELECT count(*) FROM facilities').fetchone()[0] == 0
        assert connection.execute('SELECT count(*) FROM sources').fetchone()[0] == 14


def test_import_is_idempotent_and_preserves_admin_edits(database):
    first = import_app_data.import_data(database)
    assert first['status'] == 'imported'
    assert first['articles'] == 24 and first['facilities'] == 0
    assert import_app_data.import_data(database)['status'] == 'unchanged'
    article = build()['articles'][0]
    with psycopg.connect(database) as connection:
        connection.execute('UPDATE articles SET title=%s WHERE id=%s', ('Admin edited title', article['id']))
    assert import_app_data.import_data(database)['status'] == 'preserved_existing_data'
    with psycopg.connect(database) as connection:
        assert connection.execute('SELECT title FROM articles WHERE id=%s', (article['id'],)).fetchone()[0] == 'Admin edited title'
