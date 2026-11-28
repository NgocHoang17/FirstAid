const { Assistant } = require('./assistant.service');
const { normalizeImage, uploadMiddleware, imageParts } = require('../media/media.service');
const { ok, concurrencyLimit } = require('../../shared/api');

function registerAssistantRoutes(api, { pool, config }, options = {}) {
  const assistant = new Assistant(pool, config, options.aiTransport);
  api.post('/query', concurrencyLimit(8, async (req, res) => res.json(ok(await assistant.query(assistant.prepare(req.body, req.ip))))));
  const parseImage = uploadMiddleware('assistant');
  api.post('/query-with-image', concurrencyLimit(2, async (req, res) => {
    await new Promise((resolve, reject) => parseImage(req, res, err => err ? reject(err) : resolve()));
    const { body, image } = imageParts(req), input = assistant.prepare(body, req.ip);
    const normalized = await normalizeImage(image.buffer, image.mimetype, true);
    res.json(ok(await assistant.query(input, normalized)));
  }));
}

module.exports = { registerAssistantRoutes };
