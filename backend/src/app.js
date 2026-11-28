const express = require('express');
const cors = require('cors');
const { auth } = require('./modules/auth/auth');
const { transaction } = require('./database/pool');
const { invalid, notFound, isObject, errorHandler } = require('./shared/api');
const { registerCatalogRoutes } = require('./modules/catalog/catalog.routes');
const { registerArticleRoutes } = require('./modules/articles/article.routes');
const { registerMediaRoutes } = require('./modules/media/media.routes');
const { registerSnapshotRoutes } = require('./modules/snapshot/snapshot.routes');
const { registerAssistantRoutes } = require('./modules/assistant/assistant.routes');

function createApp(pool, config, options = {}) {
  const app = express(), security = auth(pool, config);
  app.disable('x-powered-by'); app.disable('etag');
  app.set('trust proxy', config.trustProxy);
  app.use('/api', cors({ origin: config.adminOrigin, credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], allowedHeaders: ['Content-Type', 'X-CSRF-TOKEN', 'If-None-Match'], exposedHeaders: ['ETag'] }));
  app.use((req, res, next) => { res.set({ 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'no-store', 'X-Frame-Options': 'DENY' }); next(); });
  app.use(security.middleware);
  // CSRF is checked before parsing an admin body or accepting upload bytes.
  app.use('/api/v1/admin', security.csrf);
  app.use(express.json({ limit: '1mb', strict: true }));
  app.use((req, res, next) => {
    if (req.is('application/json') && !isObject(req.body)) throw invalid('request', 'Cần đối tượng JSON');
    if (['POST', 'PUT'].includes(req.method) && !req.is('multipart/form-data') && !req.is('application/json')) throw invalid('request', 'Cần application/json');
    next();
  });
  app.use('/api/v1/admin/auth', security.router);

  const api = express.Router(), admin = express.Router(), assistant = express.Router();
  admin.use(security.requireAdmin);
  // Every operation receives the same transaction connection, including nested services.
  const context = { pool, config, read: work => transaction(pool, work, true), write: work => transaction(pool, work) };
  registerCatalogRoutes(api, admin, context);
  registerArticleRoutes(api, admin, context);
  registerMediaRoutes(api, admin, context);
  registerSnapshotRoutes(api, context);
  registerAssistantRoutes(assistant, context, options);
  api.use('/assistant', assistant);
  app.use('/api/v1/admin', admin);
  app.use('/api/v1', api);

  app.use((req, res, next) => next(notFound()));
  app.use(errorHandler);
  app.locals.sessionStore = security.store;
  return app;
}

module.exports = { createApp };
