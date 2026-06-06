const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

/**
 * Multer + Cloudinary middleware for image uploads
 */

// === CHAT MEDIA (images + videos) ===
const chatStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => {
    const isVideo = file.mimetype.startsWith('video/');
    if (isVideo) {
      return {
        folder: 'walktogether/chat',
        resource_type: 'video',
        allowed_formats: ['mp4', 'mov', 'webm', 'avi'],
        eager_async: true,
        eager: [{ quality: 'auto', fetch_format: 'mp4' }],
      };
    }
    return {
      folder: 'walktogether/chat',
      resource_type: 'image',
      allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'],
      transformation: [{ width: 1024, height: 1024, crop: 'limit', quality: 'auto', fetch_format: 'auto' }],
    };
  },
});

// === POST MEDIA (images + videos) ===
const postStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => {
    const isVideo = file.mimetype.startsWith('video/');
    if (isVideo) {
      return {
        folder: 'walktogether/posts',
        resource_type: 'video',
        allowed_formats: ['mp4', 'mov', 'webm', 'avi'],
        // Use eager_async to avoid "Video too large for synchronous processing"
        eager_async: true,
        eager: [{ quality: 'auto', fetch_format: 'mp4' }],
      };
    }
    return {
      folder: 'walktogether/posts',
      resource_type: 'image',
      allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'],
      transformation: [{ width: 1920, height: 1920, crop: 'limit', quality: 'auto', fetch_format: 'auto' }],
    };
  },
});

// === AVATAR IMAGES ===
const avatarStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'walktogether/avatars',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    transformation: [{ width: 512, height: 512, crop: 'fill', gravity: 'face', quality: 'auto', fetch_format: 'auto' }],
  },
});

const fileFilter = (req, file, cb) => {
  const allowedMimes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'image/heic', 'image/heif',  // iPhone default format
    'video/mp4', 'video/quicktime', 'video/webm', 'video/x-msvideo',
  ];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ hỗ trợ file ảnh (jpg, png, gif, webp, heic) hoặc video (mp4, mov, webm)'), false);
  }
};

// Chat upload: single file (image or video), 50MB max
const chatUpload = multer({
  storage: chatStorage,
  limits: { fileSize: 50 * 1024 * 1024 },
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

