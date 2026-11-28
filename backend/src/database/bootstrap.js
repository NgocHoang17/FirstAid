const { randomUUID, createHash } = require('node:crypto');
const bcrypt = require('bcryptjs');
const { transaction } = require('./pool');
async function bootstrap(pool, config) {
  const hash = config.seedUsername ? await bcrypt.hash(config.seedPassword, 10) : null;
  await transaction(pool, async db => {
    if (hash) await db.query('INSERT INTO admin_users(id,username,password_hash,enabled) VALUES($1,$2,$3,true) ON CONFLICT(username) DO NOTHING', [randomUUID(), config.seedUsername, hash]);
    const fingerprint = createHash('sha256').update([config.locale, config.region, config.emergencyNumber].join('\n')).digest('hex');
    await db.query('UPDATE public_data_state SET config_fingerprint=$1,data_version=$2,updated_at=now() WHERE id=1 AND config_fingerprint<>$1', [fingerprint, randomUUID()]);
  });
}
module.exports = { bootstrap };
