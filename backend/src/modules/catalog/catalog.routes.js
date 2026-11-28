const { Catalog } = require('./catalog.service');
const { checks: C, ok } = require('../../shared/api');
const { pageParams, bounded, searchCatalog } = require('../../shared/query-params');

function registerCatalogRoutes(api, admin, { read, write }) {
  for (const [resource, single, save, remove] of [
    ['categories', 'category', 'saveCategory', 'deleteCategory'], ['sources', 'source', 'saveSource', 'deleteSource'],
  ]) {
    admin.get('/' + resource, async (req, res) => {
      const { page, size } = pageParams(req.query);
      const query = C.text(req.query, 'q', 2000);
      const all = searchCatalog(await read(db => new Catalog(db)[resource](true)), query);
      res.json(ok({ items: all.slice((page - 1) * size, page * size), page, page_size: size, total: all.length }));
    });
    admin.get('/' + resource + '/:id', async (req, res) => res.json(ok(await read(db => new Catalog(db)[single](C.uuid(req.params, 'id'))))));
    admin.post('/' + resource, async (req, res) => res.status(201).json(ok(await write(db => new Catalog(db)[save](null, req.body)))));
    admin.put('/' + resource + '/:id', async (req, res) => res.json(ok(await write(db => new Catalog(db)[save](C.uuid(req.params, 'id'), req.body)))));
    admin.delete('/' + resource + '/:id', async (req, res) => { await write(db => new Catalog(db)[remove](C.uuid(req.params, 'id'))); res.status(204).end(); });
  }
  api.get('/categories', async (req, res) => res.json(ok(bounded(await read(db => new Catalog(db).categories(false)), 30))));
  api.get('/sources', async (req, res) => res.json(ok(bounded(await read(db => new Catalog(db).sources(false)), 100))));
  api.get('/sources/:id', async (req, res) => res.json(ok(await read(db => new Catalog(db).source(C.uuid(req.params, 'id'), false)))));
}

module.exports = { registerCatalogRoutes };
