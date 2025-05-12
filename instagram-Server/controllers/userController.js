const User = require('../models/usersModel')
const cloudinary = require('../utils/cloudinary')
const streamifier = require('streamifier');
const notify = require('../utils/notification')

// Helper to upload from buffer
const uploadToCloudinary = (buffer) => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: 'profileImages' },
      (error, result) => {
        if (error) return reject(error);
        resolve(result);
      }
    );
    streamifier.createReadStream(buffer).pipe(stream);
  });
};


exports.updateUserInfo = async (req, res) => {
  try {
    console.log('Request received to update user info');
    console.log('Request body:', req.body);
    console.log('Request file:', req.file ? 'File exists' : 'No file');
    if (req.file) {
      console.log('File details:', {
        fieldname: req.file.fieldname,
        mimetype: req.file.mimetype,
        size: req.file.size
      });
    }

    const { username, fullName, bio } = req.body;
    const { userId } = req.user
    console.log(userId)

    let profileImageUrl;

    if (req.file) {
      console.log('Uploading file to Cloudinary...');
      const result = await uploadToCloudinary(req.file.buffer);
      profileImageUrl = result.secure_url;
      console.log('File uploaded successfully:', profileImageUrl);
    }

    const updatedFields = {
      ...(username && { username }),
      ...(fullName && { fullName }),
      ...(bio && { bio }),
      ...(profileImageUrl && { profileImage: profileImageUrl }),
    };

    console.log('Updating user with fields:', updatedFields);

    const updatedUser = await User.findByIdAndUpdate(userId, updatedFields, { new: true });

    if (!updatedUser) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    console.log('User updated successfully');
    res.status(200).json({ message: 'User updated successfully', user: updatedUser });
  } catch (err) {
    console.error('Update Error:', err);
    res.status(500).json({ message: 'Something went wrong' });
  }
};


exports.loadUserInfo = async (req, res) => {
  try {
    const { userId } = req.user;

    const userInfo = await User.findById(userId).select('username fullName bio profileImage');

    if (!userInfo) {
      return res.status(404).json({ message: 'User not found.', success: false });
    }

    return res.status(200).json({
      success: true,
      userInfo,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      message: 'An error occurred while loading user info.',
      success: false,
    });
  }
};

exports.loadAllUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select('_id username fullName bio profileImage followers following')
      .populate('followers', 'username profileImage')
      .populate('following', 'username profileImage')
      .lean();

    if (!users || users.length === 0) {
      return res.status(404).json({ message: 'No users found.', success: false });
    }

    return res.status(200).json({
      success: true,
      users
    });
  } catch (error) {
    console.error('Error loading all users:', error);
    return res.status(500).json({
      message: 'An error occurred while loading users.',
      success: false
    });
  }
};

exports.followUser = async (req, res) => {
  try {
    const currentUserId = req.user?.userId;

    const { userIdToFollow } = req.body;
    console.log('req.user:', req.user);
    console.log('req.body:', req.body);
    if (!currentUserId || !userIdToFollow) {
      return res.status(400).json({ message: 'Missing user ID(s).' });
    }

    if (currentUserId === userIdToFollow) {
      return res.status(400).json({ message: "You can't follow yourself." });
    }

    const currentUser = await User.findById(currentUserId);
    const targetUser = await User.findById(userIdToFollow);

    if (!currentUser) {
      return res.status(404).json({ message: 'Current user not found.' });
    }

    if (!targetUser) {
      return res.status(404).json({ message: 'User to follow not found.' });
    }

    const isFollowing = currentUser.following.includes(userIdToFollow);

    if (isFollowing) {
      currentUser.following = currentUser.following.filter(
        id => id.toString() !== userIdToFollow
      );
      targetUser.followers = targetUser.followers.filter(
        id => id.toString() !== currentUserId
      );
      await currentUser.save();
      await targetUser.save();
      return res.status(200).json({ message: 'User unfollowed.', success: true });
    } else {
      currentUser.following.push(userIdToFollow);
      targetUser.followers.push(currentUserId);
      await currentUser.save();
      await targetUser.save();
     // 🔔 Send follow notification
     await notify(
      {
        type: 'follow',
        fromUser: currentUserId,
        toUser: userIdToFollow,
        post: null
      },
      req.io,
      req.onlineUsers
    );
      return res.status(200).json({ message: 'User followed.', success: true });
    }

  } catch (err) {
    console.error('Error toggling follow:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUserWithFollowInfo = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id)
      .populate('followers', 'username profileImage')
      .populate('following', 'username profileImage')
      .lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    res.status(200).json({ success: true, user });
  } catch (error) {
    console.error('Error getting user follow info:', error);
    res.status(500).json({ message: 'Server error' });
  }
};


exports.findUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('_id username fullName profileImage')
      .lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found', success: false });
    }

    res.status(200).json(user);
  } catch (error) {
    console.error('Error finding user by ID:', error);
    res.status(500).json({ message: 'Server error', success: false });
  }
};