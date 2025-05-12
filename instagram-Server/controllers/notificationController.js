const Notification = require('../models/notification');
const Post = require('../models/postModel');

exports.createNotification = async (req, res) => {
  const { type, fromUser, toUser, post } = req.body;
  const io = req.io;
  const onlineUsers = req.onlineUsers;

  if (fromUser === toUser) {
    return res.status(400).json({ error: "Can't notify yourself" });
  }

  try {
    const notification = new Notification({ type, fromUser, toUser, post });
    await notification.save();

    const targetSocketId = onlineUsers[toUser];

    // Only emit if recipient is online
    if (targetSocketId) {
      let postPayload = null;

      // If the notification is related to a post (like/comment), include full post info
      if (post) {
        const fullPost = await Post.findById(post)
          .populate('userId', 'username profileImage')
          .lean();

        if (fullPost) {
          postPayload = {
            id: fullPost._id.toString(),
            imageUrl: fullPost.imageUrl,
            videoUrl: fullPost.videoUrl,
            caption: fullPost.caption,
            mediaType: fullPost.mediaType,
            likes: fullPost.likes || [],
            comments: fullPost.comments || [],
            date: fullPost.createdAt,
            userId: {
              id: fullPost.userId._id.toString(),
              username: fullPost.userId.username,
              profileImage: fullPost.userId.profileImage,
              followers: fullPost.userId.followers || [],
              following: fullPost.userId.following || [],
            }
          };
        }
      }

      io.to(targetSocketId).emit('new-notification', {
        id: notification._id.toString(),
        type,
        fromUser,
        post: postPayload,
        createdAt: notification.createdAt,
      });
    }

    res.status(201).json(notification);
  } catch (error) {
    console.error('❌ Error creating notification:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
};

exports.getNotificationsForUser = async (req, res) => {
  const { userId } = req.params;

  try {
    const notifications = await Notification.find({ toUser: userId })
      .populate('fromUser', 'username profileImage')
      .populate({
        path: 'post',
        populate: {
          path: 'userId',
          select: 'username profileImage followers following'
        }
      })
      .sort({ createdAt: -1 })
      .limit(50);

    // Transform notifications to match expected Swift format
    const formatted = notifications.map((notif) => ({
      id: notif._id.toString(),
      type: notif.type,
      fromUser: notif.fromUser,
      createdAt: notif.createdAt,
      post: notif.post
        ? {
            id: notif.post._id.toString(),
            imageUrl: notif.post.imageUrl,
            videoUrl: notif.post.videoUrl,
            caption: notif.post.caption,
            mediaType: notif.post.mediaType,
            likes: notif.post.likes || [],
            comments: notif.post.comments || [],
            date: notif.post.createdAt,
            userId: notif.post.userId
              ? {
                  id: notif.post.userId._id.toString(),
                  username: notif.post.userId.username,
                  profileImage: notif.post.userId.profileImage,
                  followers: notif.post.userId.followers || [],
                  following: notif.post.userId.following || [],
                }
              : null,
          }
        : null,
    }));

    res.json(formatted);
  } catch (error) {
    console.error('❌ Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to load notifications' });
  }
};
