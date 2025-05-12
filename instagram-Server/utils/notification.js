// utils/createNotification.js
module.exports = async function notify({ type, fromUser, toUser, post }, io, onlineUsers) {
    const Notification = require('../models/notification')
    
    if (fromUser === toUser) return;
  
    const notification = new Notification({ type, fromUser, toUser, post });
    await notification.save();
  
    const targetSocket = onlineUsers[toUser];
    if (targetSocket) {
      io.to(targetSocket).emit('new-notification', {
        type,
        fromUser,
        post,
        date: notification.createdAt
      });
    }
  };
  