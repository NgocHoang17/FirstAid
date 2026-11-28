const { Articles } = require('./article.service');
const { checks: C, ok } = require('../../shared/api');
const { pageParams, filters } = require('../../shared/query-params');

function registerArticleRoutes(api, admin, { config, read, write }) {
  admin.get('/articles', async (req, res) => {
    const { page, size } = pageParams(req.query), filter = filters(req.query);
    const data = await read(async db => {
      const service = new Articles(db, config);
      return { items: await service.list(filter, true, page, size), page, page_size: size, total: await service.count(filter) };
    });
    res.json(ok(data));
  });
  admin.get('/articles/:id', async (req, res) => res.json(ok(await read(db => new Articles(db, config).get(C.uuid(req.params, 'id'), true)))));
  admin.post('/articles', async (req, res) => res.status(201).json(ok(await write(db => new Articles(db, config).save(null, req.body)))));
  admin.put('/articles/:id', async (req, res) => res.json(ok(await write(db => new Articles(db, config).save(C.uuid(req.params, 'id'), req.body)))));
  admin.delete('/articles/:id', async (req, res) => { await write(db => new Articles(db, config).delete(C.uuid(req.params, 'id'))); res.status(204).end(); });
  for (const action of ['publish', 'unpublish']) admin.post(`/articles/:id/${action}`, async (req, res) => res.json(ok(await write(db => new Articles(db, config)[action](C.uuid(req.params, 'id'), C.revision(req.body))))));

  api.get('/articles', async (req, res) => res.json(ok({ items: await read(db => new Articles(db, config).list(filters(req.query))) })));
  api.get('/articles/:id', async (req, res) => res.json(ok(await read(db => new Articles(db, config).get(C.uuid(req.params, 'id'))))));
}

module.exports = { registerArticleRoutes };
