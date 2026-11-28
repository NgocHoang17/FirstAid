-- Session storage for Node.js. Domain tables and legacy facility data are retained.
CREATE TABLE admin_sessions (
    sid varchar NOT NULL PRIMARY KEY,
    sess json NOT NULL,
    expire timestamp(6) NOT NULL
);
CREATE INDEX admin_sessions_expire_idx ON admin_sessions(expire);
