-- FirstAid P0 local cache schema. Apply in Flutter's SQLite migration.
-- On every connection run PRAGMA foreign_keys = ON before any transaction.
-- JSON arrays are TEXT; the app validates JSON shape before insertion.
-- This schema accepts only a validated public OfflineSnapshot schema 1.

CREATE TABLE app_metadata (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL CHECK (schema_version = 1),
    data_version TEXT NOT NULL,
    generated_at TEXT NOT NULL,
    region_code TEXT NOT NULL,
    locale TEXT NOT NULL,
    emergency_number TEXT NOT NULL
);

CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    group_code TEXT NOT NULL CHECK (group_code IN ('CIRCULATION', 'TRAUMA', 'ENVIRONMENT', 'OTHER')),
    description TEXT NOT NULL,
    keywords_json TEXT NOT NULL DEFAULT '[]',
    sort_order INTEGER NOT NULL,
    is_active INTEGER NOT NULL CHECK (is_active = 1)
);
CREATE INDEX categories_sort_idx ON categories (sort_order, code);

CREATE TABLE sources (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    publisher TEXT NOT NULL,
    publication_year INTEGER,
    media_type TEXT NOT NULL CHECK (media_type IN ('PDF', 'WEB')),
    page_count INTEGER,
    revision INTEGER NOT NULL CHECK (revision >= 1),
    original_url TEXT,
    is_active INTEGER NOT NULL CHECK (is_active = 1),
    rights_note TEXT,
    CHECK (
        (media_type = 'PDF' AND page_count IS NOT NULL AND page_count > 0)
        OR (media_type = 'WEB' AND page_count IS NULL
            AND original_url IS NOT NULL AND original_url LIKE 'https://%')
    )
);

CREATE TABLE articles (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    slug TEXT NOT NULL UNIQUE,
    variant_key TEXT NOT NULL,
    title TEXT NOT NULL,
    age_group TEXT NOT NULL CHECK (age_group IN ('ADULT', 'CHILD', 'ALL')),
    applies_to TEXT NOT NULL,
    summary TEXT NOT NULL,
    recognition_json TEXT NOT NULL DEFAULT '[]',
    quick_actions_json TEXT NOT NULL DEFAULT '[]',
    warnings_json TEXT NOT NULL DEFAULT '[]',
    seek_help_json TEXT NOT NULL DEFAULT '[]',
    status TEXT NOT NULL CHECK (status = 'PUBLISHED'),
    content_checked INTEGER NOT NULL CHECK (content_checked = 1),
    checked_at TEXT NOT NULL,
    content_revision INTEGER NOT NULL CHECK (content_revision >= 1),
    updated_at TEXT NOT NULL,
    UNIQUE (category_id, variant_key)
);
CREATE INDEX articles_category_age_idx ON articles (category_id, age_group);

CREATE TABLE article_steps (
    id TEXT PRIMARY KEY,
    article_id TEXT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    position INTEGER NOT NULL CHECK (position >= 1),
    title TEXT NOT NULL,
    instruction TEXT NOT NULL,
    asset_key TEXT,
    image_url TEXT,
    alt_text TEXT,
    UNIQUE (article_id, position),
    CHECK (image_url IS NULL OR image_url LIKE 'https://%'),
    CHECK ((asset_key IS NULL AND image_url IS NULL) OR (alt_text IS NOT NULL AND trim(alt_text) <> ''))
);

CREATE TABLE article_references (
    id TEXT PRIMARY KEY,
    article_id TEXT NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    source_id TEXT NOT NULL REFERENCES sources(id) ON DELETE RESTRICT,
    position INTEGER NOT NULL CHECK (position >= 1),
    page_start INTEGER,
    page_end INTEGER,
    section_key TEXT NOT NULL DEFAULT 'all',
    note TEXT,
    UNIQUE (article_id, position),
    CHECK (
        (page_start IS NULL AND page_end IS NULL)
        OR (page_start IS NOT NULL AND page_end IS NOT NULL
            AND page_start >= 1 AND page_end >= page_start)
    )
);
CREATE INDEX article_references_source_idx ON article_references (source_id);

CREATE TABLE facilities (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    region_code TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT NOT NULL,
    latitude REAL NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    emergency_24h TEXT NOT NULL CHECK (emergency_24h IN ('YES', 'NO', 'UNKNOWN')),
    verification_note TEXT NOT NULL,
    verified_at TEXT NOT NULL,
    is_active INTEGER NOT NULL CHECK (is_active = 1)
);
CREATE INDEX facilities_region_name_idx ON facilities (region_code, name);
