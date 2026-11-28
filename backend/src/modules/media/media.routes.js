const { randomUUID } = require('node:crypto');
const { normalizeImage, uploadMiddleware } = require('./media.service');
const { checks: C, invalid, notFound, ok } = require('../../shared/api');
const { publicFilter } = require('../../database/row-mappers');

function registerMediaRoutes(api, admin, { pool, read }) {
  admin.post('/media', uploadMiddleware('admin'), async (req, res) => {
    if (!req.file) throw invalid('file', 'Cần một ảnh');
    const image = await normalizeImage(req.file.buffer), id = randomUUID();
    await pool.query('INSERT INTO media_assets(id,mime_type,width,height,content) VALUES($1,$2,$3,$4,$5)', [id, image.mime, image.width, image.height, image.bytes]);
    res.status(201).json(ok({ id, url: '/api/v1/media/' + id, width: image.width, height: image.height }));
  });
  api.get('/media/:id', async (req, res) => {
    const id = C.uuid(req.params, 'id');
    const image = await read(async db => {
      const isAdmin = req.session.adminId && (await db.query('SELECT 1 FROM admin_users WHERE id=$1 AND enabled=true', [req.session.adminId])).rowCount;
      const result = await db.query(`SELECT m.mime_type,m.content FROM media_assets m WHERE m.id=$1 ${isAdmin ? '' : `AND EXISTS (
        SELECT 1 FROM article_steps st JOIN articles a ON a.id=st.article_id JOIN categories c ON c.id=a.category_id
        WHERE ${publicFilter} AND st.images_json @> $2::jsonb)`}`, isAdmin ? [id] : [id, JSON.stringify([{ media_id: id }])]);
      if (!result.rows[0]) throw notFound();
      return result.rows[0];
    });
    res.set('Cache-Control', 'private, no-store').type(image.mime_type).send(image.content);
  });
}

module.exports = { registerMediaRoutes };
