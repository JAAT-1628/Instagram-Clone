const Post = require('../models/postModel'); // Import the Post model
const cloudinary = require('../utils/cloudinary'); // Your existing cloudinary config
const upload = require('../middlewares/multer'); // Your existing multer config
const { StatusCodes } = require('http-status-codes');
const mongoose = require('mongoose');
const notify = require('../utils/notification')

// for uploading reels or video
exports.uploadReel = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Video file is required'
      });
    }

    if (!req.user || !req.user.id) {
      return res.status(StatusCodes.UNAUTHORIZED).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const b64 = Buffer.from(req.file.buffer).toString('base64');
    const dataURI = `data:${req.file.mimetype};base64,${b64}`;

    const result = await cloudinary.uploader.upload(dataURI, {
      folder: 'reels',
      resource_type: 'video'
    });

    const post = new Post({
      userId: req.user.id,
      videoUrl: result.secure_url,
      caption: req.body.caption || '',
      mediaType: 'video'
    });

    await post.save();

    res.status(StatusCodes.CREATED).json({
      success: true,
      message: 'Reel uploaded successfully',
      post
    });
  } catch (error) {
    console.error('Error uploading reel:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Error uploading reel',
      error: error.message
    });
  }
};

// get all reels
exports.getReels = async (req, res) => {
  try {
    const reels = await Post.find({ mediaType: 'video' })
      .populate('userId', 'username profileImage')
      .sort({ date: -1 });

    res.status(StatusCodes.OK).json({ success: true, posts: reels });
  } catch (error) {
    console.error('Error fetching reels:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Error fetching reels',
      error: error.message
    });
  }
};

// Create a new post with image upload
exports.createPost = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(StatusCodes.BAD_REQUEST).json({ 
        success: false, 
        message: 'Image is required' 
      });
    }

    if (!req.user || !req.user.id) {
      return res.status(StatusCodes.UNAUTHORIZED).json({ 
        success: false, 
        message: 'User not authenticated' 
      });
    }

    const b64 = Buffer.from(req.file.buffer).toString('base64');
    const dataURI = `data:${req.file.mimetype};base64,${b64}`;
    
    // Upload image to Cloudinary using your cloudinary config
    const result = await cloudinary.uploader.upload(dataURI, {
      folder: 'posts',
      resource_type: 'image'
    });

    // Create new post
    const post = new Post({
      userId: req.user.id,
      imageUrl: result.secure_url,
      caption: req.body.caption || '',
      // date is automatically added by default
    });

    // Save post to database
    await post.save();

    res.status(StatusCodes.CREATED).json({ 
      success: true, 
      message: 'Post created successfully',
      post 
    });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ 
      success: false, 
      message: 'Error creating post', 
      error: error.message 
    });
  }
};

// Get all posts
exports.getAllPosts = async (req, res) => {
  try {
    const posts = await Post.find()
      .populate('userId', 'username bio fullName profileImage') // Populate user details
      .sort({ date: -1 }); // Sort by newest first
    
    res.status(StatusCodes.OK).json({ success: true, posts });
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ 
      success: false, 
      message: 'Error fetching posts', 
      error: error.message 
    });
  }
};

// Get user posts
exports.getUserPosts = async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(StatusCodes.BAD_REQUEST).json({ 
        success: false, 
        message: 'Invalid user ID' 
      });
    }
    
    const posts = await Post.find({ userId })
      .sort({ date: -1 }); // Sort by newest first
    
    res.status(StatusCodes.OK).json({ success: true, posts });
  } catch (error) {
    console.error('Error fetching user posts:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ 
      success: false, 
      message: 'Error fetching user posts', 
      error: error.message 
    });
  }
};

// Like a post
exports.likePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.id;
    
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        message: 'Invalid post ID'
      });
    }
    
    const post = await Post.findById(postId);
    
    if (!post) {
      return res.status(StatusCodes.NOT_FOUND).json({
        success: false,
        message: 'Post not found'
      });
    }

    if (!Array.isArray(post.likes)) {
      post.likes = []; // Fix corrupt or undefined likes array
    }
    
    // Check if user has already liked the post
    const userLikedIndex = post.likes.findIndex(
      (id) => id.toString() === userId.toString()
    );
    
    let message = '';
    let liked = false;
    
    if (userLikedIndex === -1) {
      // User hasn't liked the post yet, add like
      post.likes.push(userId);
      message = 'Post liked successfully';
      liked = true;
      // 🔔 Send like notification
      if (userId !== post.userId.toString()) {
        await notify(
          {
            type: 'like',
            fromUser: userId,
            toUser: post.userId.toString(),
            post: postId
          },
          req.io,
          req.onlineUsers
        );
      }
    } else {
      // User already liked the post, remove like
      post.likes.splice(userLikedIndex, 1);
      message = 'Post unliked successfully';
      liked = false;
    }
    
    await post.save();
    
    res.status(StatusCodes.OK).json({
      success: true,
      message: message,
      likes: post.likes.length, // This will be 0 for a post with no likes
      liked: liked
    });
  } catch (error) {
    console.error('Error processing like:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      message: 'Error processing like',
      error: error.message
    });
  }
};

// Delete a post
exports.deletePost = async (req, res) => {
  try {
    const { postId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(StatusCodes.BAD_REQUEST).json({ 
        success: false, 
        message: 'Invalid post ID' 
      });
    }
    
    const post = await Post.findById(postId);
    
    if (!post) {
      return res.status(StatusCodes.NOT_FOUND).json({ 
        success: false, 
        message: 'Post not found' 
      });
    }
    
    // Check if user owns the post
    if (post.userId.toString() !== req.user.id) {
      return res.status(StatusCodes.FORBIDDEN).json({ 
        success: false, 
        message: 'Not authorized to delete this post' 
      });
    }
    
    if (post.imageUrl || post.videoUrl) {
      const mediaUrl = post.imageUrl || post.videoUrl;
      const urlParts = mediaUrl.split('/');
      const publicIdWithExtension = urlParts[urlParts.length - 1];
      const publicId = `posts/${publicIdWithExtension.split('.')[0]}`;
    
      await cloudinary.uploader.destroy(publicId);
    }
    
    // Delete post from database
    await Post.findByIdAndDelete(postId);
    
    res.status(StatusCodes.OK).json({ 
      success: true, 
      message: 'Post deleted successfully' 
    });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ 
      success: false, 
      message: 'Error deleting post', 
      error: error.message 
    });
  }
};

exports.commentPost = async (req, res) => {
  try {
    const { postId } = req.params;
    const { text } = req.body;
    const userId = req.user.id;

    // Validate postId
    if (!mongoose.Types.ObjectId.isValid(postId)) {
      return res.status(StatusCodes.BAD_REQUEST).json({ 
        success: false, 
        message: 'Invalid post ID' 
      });
    }

    // Validate comment text
    if (!text || text.trim() === '') {
      return res.status(StatusCodes.BAD_REQUEST).json({ 
        success: false, 
        message: 'Comment text is required' 
      });
    }

    const post = await Post.findById(postId);

    if (!post) {
      return res.status(StatusCodes.NOT_FOUND).json({ 
        success: false, 
        message: 'Post not found' 
      });
    }

    // Create and add comment
    const newComment = {
      userId: userId,
      text: text.trim(),
    };
    
    post.comments.push(newComment);
    await post.save();

    // Populate for response
    const populatedPost = await Post.findById(postId)
      .populate('userId', 'username profileImage')
      .populate('comments.userId', 'username profileImage');

    // 🔔 Send comment notification (not to self)
    if (userId !== post.userId.toString()) {
      await notify(
        {
          type: 'comment',
          fromUser: userId,
          toUser: post.userId.toString(),
          post: postId
        },
        req.io,
        req.onlineUsers
      );
    }

    res.status(StatusCodes.OK).json({ 
      success: true,
      message: 'Comment added successfully',
      post: populatedPost
    });

  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ 
      success: false, 
      message: 'Error adding comment', 
      error: error.message 
    });
  }
};