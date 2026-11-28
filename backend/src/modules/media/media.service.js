const sharp = require('sharp');
const multer = require('multer');
const { ApiFailure, invalid } = require('../../shared/api');
const MAX_IMAGE = 5 * 1024 * 1024;
function uploadMiddleware(kind) {
  const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: MAX_IMAGE, files: kind === 'admin' ? 1 : 2, fields: kind === 'admin' ? 0 : 1, parts: kind === 'admin' ? 1 : 2, fieldSize: 60000, fieldNameSize: 100 } });
  const parse = kind === 'admin' ? upload.single('file') : upload.fields([{ name: 'request', maxCount: 1 }, { name: 'image', maxCount: 1 }]);
  return (req, res, next) => {
    if (!req.is('multipart/form-data')) return next(invalid('request', 'Cần multipart/form-data'));
    parse(req, res, err => {
      if (err && !(err instanceof multer.MulterError)) return next(invalid('request', 'Multipart không hợp lệ'));
      next(err);
    });
  };
}
async function normalizeImage(bytes, mime = null, assistant = false) {
  const unsupported = () => assistant ? new ApiFailure(415, 'IMAGE_UNSUPPORTED', 'Chỉ nhận ảnh JPEG hoặc PNG hợp lệ') : invalid('file', 'Chỉ nhận ảnh JPEG hoặc PNG hợp lệ');
  const tooLarge = () => new ApiFailure(413, 'IMAGE_TOO_LARGE', 'Ảnh tối đa 5 MB và 16 megapixel');
  if (!bytes?.length) throw unsupported();
  if (bytes.length > MAX_IMAGE) throw tooLarge();
  try {
    const image = sharp(bytes, { limitInputPixels: 16000000, failOn: 'warning' });
    const metadata = await image.metadata();
    if (!['jpeg', 'png'].includes(metadata.format) || (metadata.pages || 1) !== 1 || (assistant && mime !== 'image/' + metadata.format)) throw unsupported();
    if (!metadata.width || !metadata.height || metadata.width * metadata.height > 16000000) throw tooLarge();
    // Re-encode pixels and omit metadata. Never trust filename, extension or MIME alone.
    const { data, info } = await image.rotate().toFormat(metadata.format).toBuffer({ resolveWithObject: true });
    if (data.length > MAX_IMAGE) throw tooLarge();
    return { bytes: data, mime: 'image/' + metadata.format, width: info.width, height: info.height };
  } catch (err) {
    if (err instanceof ApiFailure) throw err;
    if (/pixel limit/i.test(err.message)) throw tooLarge();
    throw unsupported();
  }
}
function imageParts(req) {
  const requestFiles = req.files?.request || [], imageFiles = req.files?.image || [];
  const fields = Object.keys(req.body || {});
  if (imageFiles.length !== 1 || requestFiles.length + (Object.hasOwn(req.body || {}, 'request') ? 1 : 0) !== 1 || fields.some(k => k !== 'request')) throw invalid('request', 'Cần đúng hai part request và image');
  const file = requestFiles[0];
  if (file && (file.mimetype !== 'application/json' || file.size > 60000)) throw invalid('request');
  try {
    return { body: JSON.parse(file ? file.buffer.toString('utf8') : req.body.request), image: imageFiles[0] };
  } catch { throw invalid('request', 'JSON không hợp lệ'); }
}
module.exports = { normalizeImage, uploadMiddleware, imageParts, MAX_IMAGE };
