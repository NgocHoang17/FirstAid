-- FirstAid P0 reference DDL, PostgreSQL 15+.
-- Apply once through a migration tool after adding PostgreSQL persistence.
-- Application supplies UUIDs for domain rows; timestamps are UTC instants.

CREATE TABLE admin_users (
    id uuid PRIMARY KEY,
    username varchar(100) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT admin_username_nonblank CHECK (btrim(username) <> ''),
    CONSTRAINT admin_password_hash_nonblank CHECK (btrim(password_hash) <> '')
);

CREATE TABLE categories (
    id uuid PRIMARY KEY,
    code varchar(4) NOT NULL UNIQUE,
    name varchar(200) NOT NULL,
    group_code varchar(20) NOT NULL,
    description text NOT NULL DEFAULT '',
    keywords_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    coverage_note text,
    audience_policy text,
    pdf_evidence_json jsonb,
    sort_order integer NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT category_code_format CHECK (code ~ '^FA[0-9]{2}$'),
    CONSTRAINT category_name_nonblank CHECK (btrim(name) <> ''),
    CONSTRAINT category_group_enum CHECK (group_code IN ('CIRCULATION', 'TRAUMA', 'ENVIRONMENT', 'OTHER')),
    CONSTRAINT category_keywords_array CHECK (jsonb_typeof(keywords_json) = 'array'),
    CONSTRAINT category_pdf_evidence_object CHECK (pdf_evidence_json IS NULL OR jsonb_typeof(pdf_evidence_json) = 'object'),
    CONSTRAINT category_sort_nonnegative CHECK (sort_order >= 0)
);

CREATE INDEX categories_sort_idx ON categories (sort_order, code);

CREATE TABLE sources (
    id uuid PRIMARY KEY,
    code varchar(80) NOT NULL UNIQUE,
    title varchar(300) NOT NULL,
    publisher text NOT NULL,
    publication_year integer,
    media_type varchar(3) NOT NULL,
    page_count integer,
    revision bigint NOT NULL DEFAULT 1,
    original_url text,
    accessed_at date,
    is_active boolean NOT NULL DEFAULT true,
    rights_note text,
    CONSTRAINT source_code_nonblank CHECK (btrim(code) <> ''),
    CONSTRAINT source_title_nonblank CHECK (btrim(title) <> ''),
    CONSTRAINT source_publisher_nonblank CHECK (btrim(publisher) <> ''),
    CONSTRAINT source_publication_year_valid CHECK (publication_year IS NULL OR publication_year BETWEEN 1000 AND 9999),
    CONSTRAINT source_revision_positive CHECK (revision >= 1),
    CONSTRAINT source_media_rules CHECK (
        (media_type = 'PDF' AND page_count IS NOT NULL AND page_count > 0
            AND (original_url IS NULL OR original_url ~* '^https://'))
        OR (media_type = 'WEB' AND page_count IS NULL
            AND original_url IS NOT NULL AND original_url ~* '^https://')
    )
);

CREATE TABLE articles (
    id uuid PRIMARY KEY,
    category_id uuid NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    slug varchar(200) NOT NULL UNIQUE,
    variant_key varchar(100) NOT NULL,
    title varchar(200) NOT NULL,
    age_group varchar(8) NOT NULL,
    applies_to text NOT NULL DEFAULT '',
    summary varchar(1000) NOT NULL DEFAULT '',
    recognition_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    quick_actions_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    warnings_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    seek_help_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    status varchar(10) NOT NULL DEFAULT 'DRAFT',
    content_checked boolean NOT NULL DEFAULT false,
    checked_at timestamptz,
    content_revision bigint NOT NULL DEFAULT 1,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT article_category_variant_unique UNIQUE (category_id, variant_key),
    CONSTRAINT article_slug_nonblank CHECK (btrim(slug) <> ''),
    CONSTRAINT article_variant_nonblank CHECK (btrim(variant_key) <> ''),
    CONSTRAINT article_title_nonblank CHECK (btrim(title) <> ''),
    CONSTRAINT article_age_enum CHECK (age_group IN ('ADULT', 'CHILD', 'ALL')),
    CONSTRAINT article_status_enum CHECK (status IN ('DRAFT', 'PUBLISHED')),
    CONSTRAINT article_recognition_array CHECK (jsonb_typeof(recognition_json) = 'array'),
    CONSTRAINT article_quick_actions_array CHECK (jsonb_typeof(quick_actions_json) = 'array'),
    CONSTRAINT article_warnings_array CHECK (jsonb_typeof(warnings_json) = 'array'),
    CONSTRAINT article_seek_help_array CHECK (jsonb_typeof(seek_help_json) = 'array'),
    CONSTRAINT article_revision_positive CHECK (content_revision >= 1),
    CONSTRAINT article_checked_pair CHECK (content_checked = (checked_at IS NOT NULL)),
    CONSTRAINT article_published_checked CHECK (status <> 'PUBLISHED' OR content_checked)
);
CREATE INDEX articles_category_status_idx ON articles (category_id, status);
CREATE INDEX articles_status_age_idx ON articles (status, age_group);

CREATE TABLE article_steps (
    id uuid PRIMARY KEY,
    article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    position integer NOT NULL,
    title varchar(200) NOT NULL,
    instruction text NOT NULL,
    asset_key varchar(200),
    image_url text,
    alt_text text,
    CONSTRAINT step_article_position_unique UNIQUE (article_id, position),
    CONSTRAINT step_position_positive CHECK (position >= 1),
    CONSTRAINT step_title_nonblank CHECK (btrim(title) <> ''),
    CONSTRAINT step_instruction_nonblank CHECK (btrim(instruction) <> ''),
    CONSTRAINT step_image_https CHECK (image_url IS NULL OR image_url ~* '^https://'),
    CONSTRAINT step_visual_alt CHECK (
        (asset_key IS NULL AND image_url IS NULL)
        OR (alt_text IS NOT NULL AND btrim(alt_text) <> '')
    )
);

CREATE TABLE article_references (
    id uuid PRIMARY KEY,
    article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    source_id uuid NOT NULL REFERENCES sources(id) ON DELETE RESTRICT,
    position integer NOT NULL,
    page_start integer,
    page_end integer,
    section_key varchar(80) NOT NULL DEFAULT 'all',
    note text,
    CONSTRAINT article_reference_page_pair CHECK (
        (page_start IS NULL AND page_end IS NULL)
        OR (page_start IS NOT NULL AND page_end IS NOT NULL
            AND page_start >= 1 AND page_end >= page_start)
    ),
    CONSTRAINT article_reference_position_unique UNIQUE (article_id, position),
    CONSTRAINT article_reference_position_positive CHECK (position >= 1),
    CONSTRAINT article_reference_section_nonblank CHECK (btrim(section_key) <> '')
);

CREATE INDEX article_references_source_idx ON article_references (source_id);

CREATE TABLE facilities (
    id uuid PRIMARY KEY,
    name varchar(200) NOT NULL,
    region_code varchar(40) NOT NULL,
    address text NOT NULL,
    phone varchar(40),
    latitude numeric(9,6),
    longitude numeric(9,6),
    emergency_24h varchar(7) NOT NULL DEFAULT 'UNKNOWN',
    verification_note text,
    verified_at timestamptz,
    is_active boolean NOT NULL DEFAULT false,
    CONSTRAINT facility_name_nonblank CHECK (btrim(name) <> ''),
    CONSTRAINT facility_region_nonblank CHECK (btrim(region_code) <> ''),
    CONSTRAINT facility_address_nonblank CHECK (btrim(address) <> ''),
    CONSTRAINT facility_emergency_enum CHECK (emergency_24h IN ('YES', 'NO', 'UNKNOWN')),
    CONSTRAINT facility_coordinates_pair CHECK ((latitude IS NULL) = (longitude IS NULL)),
    CONSTRAINT facility_latitude_bounds CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT facility_longitude_bounds CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT facility_active_verified CHECK (
        NOT is_active OR (
            phone IS NOT NULL AND btrim(phone) <> ''
            AND latitude IS NOT NULL AND longitude IS NOT NULL
            AND verification_note IS NOT NULL AND btrim(verification_note) <> ''
            AND verified_at IS NOT NULL
        )
    )
);

CREATE INDEX facilities_region_active_name_idx ON facilities (region_code, is_active, name);

CREATE TABLE public_data_state (
    id smallint PRIMARY KEY DEFAULT 1,
    data_version uuid NOT NULL,
    config_fingerprint text NOT NULL DEFAULT '',
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT public_data_state_singleton CHECK (id = 1)
);
INSERT INTO public_data_state (id, data_version) VALUES (1, gen_random_uuid());
