const cloudinary = require('cloudinary').v2;
// const multer = require('multer');
// const path = require('path');
// const fs = require('fs');
// const dotenv = require('dotenv');

// dotenv.config();

// // Create uploads directory if it doesn't exist
// const uploadsDir = path.join(__dirname, '../uploads');
// if (!fs.existsSync(uploadsDir)) {
//   fs.mkdirSync(uploadsDir, { recursive: true });
// }


cloudinary.config({ 
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME, 
    api_key: process.env.CLOUDINARY_API_KEY, 
    api_secret: process.env.CLOUDINARY_API_SECRET
})

// const storage = multer.diskStorage({
//     destination: function (req, file, cb) {
//       cb(null, uploadsDir);
//     },
//     filename: function (req, file, cb) {
//       const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
//       cb(null, uniqueSuffix + path.extname(file.originalname));
//     }
//   });
  
//   // File filter for images
//   const fileFilter = (req, file, cb) => {
//     const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
//     if (allowedTypes.includes(file.mimetype)) {
//       cb(null, true);
//     } else {
//       cb(new Error('Invalid file type. Only JPEG, JPG, PNG and GIF are allowed.'), false);
//     }
//   };
  
//   // Create multer upload instance
//   const upload = multer({ 
//     storage: storage,
//     fileFilter: fileFilter,
//     limits: {
//       fileSize: 5 * 1024 * 1024 // 5MB limit
//     }
//   });
  
//   // Function to upload to Cloudinary
//   const uploadToCloudinary = async (filePath) => {
//     // Upload file to Cloudinary
//     const result = await cloudinary.uploader.upload(filePath, {
//       folder: 'uploads'
//     });
  
//     // Remove file from local storage after upload
//     fs.unlinkSync(filePath);
    
//     return result;
//   };
  
  module.exports = cloudinary;

  // module.exports = { cloudinary, upload, uploadToCloudinary };