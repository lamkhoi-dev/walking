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

// === POST MEDIA (images + videos) ===
const postStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => {
    const isVideo = file.mimetype.startsWith('video/');
    return {
      folder: 'walktogether/posts',
      resource_type: isVideo ? 'video' : 'image',
      allowed_formats: isVideo
        ? ['mp4', 'mov', 'webm', 'avi']
        : ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      transformation: isVideo
        ? [{ quality: 'auto', fetch_format: 'mp4' }]
        : [{ width: 1920, height: 1920, crop: 'limit', quality: 'auto' }],
    };
  },
});

// === AVATAR IMAGES ===
const avatarStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'walktogether/avatars',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ width: 512, height: 512, crop: 'fill', gravity: 'face', quality: 'auto' }],
  },
});

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'video/mp4', 'video/quicktime', 'video/webm', 'video/x-msvideo',
  ];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ hỗ trợ file ảnh (jpg, png, gif, webp) hoặc video (mp4, mov, webm)'), false);
  }
};

// Chat upload: single image, 5MB max
const chatUpload = multer({
  storage: chatStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});

// Post upload: up to 4 files (images or video), 50MB max each
const postUpload = multer({
  storage: postStorage,
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter,
});

// Avatar upload: single image, 5MB max
const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});

// Keep backward compatibility
const upload = chatUpload;

module.exports = { upload, chatUpload, postUpload, avatarUpload };

