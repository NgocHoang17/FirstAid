const { snapshot } = require('./snapshot.service');
const { ok } = require('../../shared/api');

function registerSnapshotRoutes(api, { config, read }) {
  api.get('/offline-snapshot', async (req, res) => {
    const data = await read(db => snapshot(db, config, req.query, req.get('If-None-Match')));
    res.set({ ETag: data.etag, 'Cache-Control': 'private, no-cache' });
    if (!data.payload) return res.status(304).end();
    res.json(ok(data.payload));
  });
}

module.exports = { registerSnapshotRoutes };
