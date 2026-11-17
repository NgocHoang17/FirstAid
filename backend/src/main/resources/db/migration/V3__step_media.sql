CREATE TABLE media_assets (
    id uuid PRIMARY KEY,
    mime_type varchar(20) NOT NULL,
    width integer NOT NULL,
    height integer NOT NULL,
    content bytea NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (mime_type IN ('image/png','image/jpeg')),
    CHECK (width > 0 AND height > 0 AND width::bigint * height <= 16000000),
    CHECK (octet_length(content) <= 5242880)
);
ALTER TABLE article_steps ADD COLUMN images_json jsonb NOT NULL DEFAULT '[]';
ALTER TABLE article_steps ADD COLUMN image_layout varchar(16) NOT NULL DEFAULT 'stacked'
    CHECK (image_layout IN ('stacked','grid','carousel'));
ALTER TABLE article_steps ADD CONSTRAINT step_images_array CHECK
    (jsonb_typeof(images_json) = 'array' AND jsonb_array_length(images_json) <= 6);
