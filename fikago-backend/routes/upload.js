// routes/upload.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authenticate, authorize } = require('../middlewares/auth');

// 1. Sanidi Multer (Wapi picha zitaenda na jina lake)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const folder = req.params.kind === 'restaurant' ? 'restaurant' : 'menu';
    const destination = path.join(__dirname, '..', 'uploads', folder);
    fs.mkdirSync(destination, { recursive: true });
    cb(null, destination);
  },
  filename: (req, file, cb) => {
    // Tengeneza jina la kipekee: menu-<timestamp>.<ext>
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `${req.params.kind}-${uniqueSuffix}${ext}`);
  },
});

// 2. Filter: Ruhusu picha za menu/mgahawa (jpg, jpeg, png, webp).
const fileFilter = (req, file, cb) => {
  const extension = path.extname(file.originalname).toLowerCase();
  const expectedMimeTypes = {
    '.jpg': ['image/jpeg', 'image/jpg'],
    '.jpeg': ['image/jpeg', 'image/jpg'],
    '.png': ['image/png'],
    '.webp': ['image/webp'],
  };
  const acceptedMimeTypes = expectedMimeTypes[extension];
  const receivedMimeType = String(file.mimetype || '').toLowerCase();

  // Some clients send application/octet-stream even when the filename has a
  // valid image extension. The mobile client supplies the correct MIME type,
  // while this fallback keeps other standard multipart clients compatible.
  if (acceptedMimeTypes && (acceptedMimeTypes.includes(receivedMimeType) ||
      receivedMimeType === 'application/octet-stream')) {
    return cb(null, true);
  }

  return cb(new Error('Picha za JPG, JPEG, PNG au WEBP pekee zinaruhusiwa.'));
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Max 5MB
  fileFilter: fileFilter,
});

// 3. Route ya Kupakia
// POST /api/upload/menu
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

    const isMalformedMultipart = err.message === 'Unexpected end of form' ||
      err.message === 'Multipart: Boundary not found';
    const status = isMalformedMultipart ? 400 : 415;
    const message = isMalformedMultipart
      ? 'Upload haijakamilika. Jaribu kuchagua picha na kupakia tena.'
      : err.message;
    return res.status(status).json({ success: false, message });
  });
}, async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Hakuna picha iliyotumwa' });
    }

    // Tengeneza URL ya picha (Inategemea na server yako)
    // Mfano: http://localhost:5000/uploads/menu/menu-1234.jpg
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.params.kind}/${req.file.filename}`;

    return res.status(200).json({
      success: true,
      message: 'Picha imepandishwa kikamilifu',
      data: {
        image_url: imageUrl,
      },
    });
  } catch (error) {
    console.error('Upload Error:', error);
    return res.status(500).json({ success: false, message: 'Imeshindwa kupandisha picha' });
  }
});

module.exports = router;
