const { existsSync, readFileSync } = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
function loadConfig(env = process.env) {
  const integer = (key, fallback, min, max) => {
    const v = Number(env[key] ?? fallback);
    if (!Number.isInteger(v) || v < min || v > max) throw new Error(`Invalid ${key}`);
    return v;
  };
  const secret = env.SESSION_SECRET || '';
  if (secret.length < 32) throw new Error('SESSION_SECRET must contain at least 32 characters');
  const username = env.ADMIN_SEED_USERNAME || '', password = env.ADMIN_SEED_PASSWORD || '';
  if ((username || password) && (!username.trim() || username.trim().length > 100 || password.length < 12 || Buffer.byteLength(password, 'utf8') > 72)) throw new Error('Set ADMIN_SEED_USERNAME and a password of at least 12 characters and at most 72 UTF-8 bytes together');
  const origin = env.ADMIN_ORIGIN || 'http://localhost:3000';
  if (new URL(origin).origin !== origin) throw new Error('ADMIN_ORIGIN must be an exact origin');
  const aiBaseUrl = (env.AI_BASE_URL || '').replace(/\/$/, '');
  if (aiBaseUrl && !['http:', 'https:'].includes(new URL(aiBaseUrl).protocol)) throw new Error('Invalid AI_BASE_URL');
  return {
    port: integer('PORT', env.SERVER_PORT || 8080, 1, 65535), host: env.HOST || '0.0.0.0',
    databaseUrl: (env.DATABASE_URL || env.DB_URL || 'postgresql://localhost:5432/firstaid').replace(/^jdbc:/, ''),
    databaseUser: env.DB_USER, databasePassword: env.DB_PASSWORD,
    sessionSecret: secret, cookieSecure: env.SESSION_COOKIE_SECURE !== 'false',
    trustProxy: integer('TRUST_PROXY_HOPS', 0, 0, 10), adminOrigin: origin,
    seedUsername: username.trim(), seedPassword: password,
    locale: env.PUBLIC_LOCALE || 'vi-VN', region: env.PUBLIC_REGION || '', emergencyNumber: env.EMERGENCY_NUMBER || '',
    aiBaseUrl, aiToken: env.AI_INTERNAL_TOKEN || '',
    aiTimeoutMs: integer('AI_REQUEST_TIMEOUT_SECONDS', 12, 5, 100) * 1000,
    aiImageTimeoutMs: integer('AI_IMAGE_TIMEOUT_SECONDS', 35, 1, 35) * 1000,
    aiMaxPerMinute: integer('AI_MAX_PER_MINUTE', 20, 1, 10000),
    assetKeys: new Set((env.ASSET_ALLOWED_KEYS || JSON.parse(readFileSync(path.join(__dirname, 'asset-keys.json'), 'utf8')).join(',')).split(',').map(s => s.trim()).filter(Boolean)),
  };
}
function loadEnv() {
  const file = path.join(root, '.env');
  if (existsSync(file)) process.loadEnvFile(file);
}
module.exports = { loadConfig, loadEnv, root };
