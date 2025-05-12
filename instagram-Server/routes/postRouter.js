const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const upload = require('../middlewares/multer'); // Your existing multer config
const authMiddleware = require('../middlewares/authMiddleware');
const { identifier } = require('../middlewares/identification');

// Create a new post with image upload - protected route
router.post('/', authMiddleware, upload.single('image'), postController.createPost);

// Get all posts
router.get('/', postController.getAllPosts);

// Get posts by specific user
router.get('/user/:userId', postController.getUserPosts);

// Like a post
router.put('/like/:postId', authMiddleware, postController.likePost);
// comment 
router.post('/comment/:postId', authMiddleware, postController.commentPost);
// Delete a post - protected route
router.delete('/:postId', authMiddleware, postController.deletePost);

// reel posting 
router.post('/reel', authMiddleware, upload.single('video'), postController.uploadReel)
router.get('/reels', postController.getReels);

module.exports = router;