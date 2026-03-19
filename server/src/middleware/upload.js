const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

/**
 * Multer + Cloudinary middleware for image uploads
 */

// === CHAT IMAGES ===
const chatStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'walktogether/chat',
    allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    transformation: [{ width: 1024, height: 1024, crop: 'limit', quality: 'auto' }],
  },
});

// === POST IMAGES ===
const postStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'walktogether/posts',
    allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    transformation: [{ width: 1920, height: 1920, crop: 'limit', quality: 'auto' }],
  },
});

const fileFilter = (req, file, cb) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ hỗ trợ file ảnh (jpg, png, gif, webp)'), false);
  }
};

// Chat upload: single image, 5MB max
const chatUpload = multer({
  storage: chatStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});

// Post upload: up to 4 images, 10MB max each
const postUpload = multer({
  storage: postStorage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter,
});

// Keep backward compatibility
const upload = chatUpload;

module.exports = { upload, chatUpload, postUpload };
