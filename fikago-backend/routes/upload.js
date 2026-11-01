const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs/promises');
const { randomUUID } = require('crypto');
const { authenticate, authorize } = require('../middlewares/auth');
const uploadsDir = path.resolve(
  process.env.UPLOADS_DIR || path.join(__dirname, '..', 'uploads'),
);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const extension = path.extname(file.originalname).toLowerCase();
    const expectedMimeTypes = {
      '.jpg': ['image/jpeg', 'image/jpg'],
      '.jpeg': ['image/jpeg', 'image/jpg'],
      '.png': ['image/png'],
      '.webp': ['image/webp'],
    };
    const acceptedMimeTypes = expectedMimeTypes[extension];
    const receivedMimeType = String(file.mimetype || '').toLowerCase();
    if (acceptedMimeTypes && (acceptedMimeTypes.includes(receivedMimeType) ||
        receivedMimeType === 'application/octet-stream')) {
      return cb(null, true);
    }
    return cb(new Error('Picha za JPG, JPEG, PNG au WEBP pekee zinaruhusiwa.'));
  },
});

router.post('/:kind', authenticate, authorize('vendor'), (req, res, next) => {
  if (!['menu', 'restaurant'].includes(req.params.kind)) {
    return res.status(404).json({ success: false, message: 'Aina ya picha haijulikani' });
  }
  next();
}, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({
        success: false,
        message: 'Picha imezidi ukubwa wa 5 MB.',
      });
    }
    const malformed = err.message === 'Unexpected end of form' ||
      err.message === 'Multipart: Boundary not found';
    return res.status(malformed ? 400 : 415).json({
      success: false,
      message: malformed
        ? 'Upload haijakamilika. Jaribu kuchagua picha na kupakia tena.'
        : err.message,
    });
  });
}, async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'Hakuna picha iliyotumwa' });
  }

  const extension = path.extname(req.file.originalname).toLowerCase();
  const filename = `${req.params.kind}-${Date.now()}-${randomUUID()}${extension}`;
  try {
    if (process.env.NODE_ENV === 'production' && !process.env.UPLOADS_DIR) {
      return res.status(503).json({
        success: false,
        message: 'Image storage haijawekwa. Weka UPLOADS_DIR kwenye Render na uunganishe persistent disk.',
      });
    }

    const folder = path.join(uploadsDir, req.params.kind);
    await fs.mkdir(folder, { recursive: true });
    await fs.writeFile(path.join(folder, filename), req.file.buffer);
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.params.kind}/${filename}`;

    return res.status(200).json({
      success: true,
      message: 'Picha imepandishwa kikamilifu',
      data: { image_url: imageUrl },
    });
  } catch (error) {
    console.error('Upload Error:', error);
    return res.status(500).json({ success: false, message: 'Imeshindwa kupandisha picha' });
  }
});

module.exports = router;
