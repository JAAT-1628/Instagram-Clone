const multer = require('multer');

// Use memory storage or disk storage
const storage = multer.memoryStorage(); // or diskStorage if uploading from path

const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/jpg',
    'video/mp4', 'video/quicktime', // mp4 and mov formats
    'video/x-matroska' // for .mkv if needed
  ];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file type'), false);
  }
};

const upload = multer({ 
  storage, fileFilter, 
  limits: {
  fileSize: 10 * 1024 * 1024 // 10MB
} });

// ✅ Export the multer instance
module.exports = upload;