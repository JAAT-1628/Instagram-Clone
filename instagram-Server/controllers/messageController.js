const Message = require('../models/messageModel');
const mongoose = require('mongoose');

exports.sendMessage = async (req, res) => {
    try {
      const { senderId, receiverId, text } = req.body;
      console.log('📨 Attempting to send message:', { senderId, receiverId, text });
  
      // Validate IDs
      if (!senderId || !mongoose.Types.ObjectId.isValid(senderId)) {
        console.error('❌ Invalid senderId:', senderId);
        return res.status(400).json({ error: 'Invalid senderId' });
      }
      
      if (!receiverId || !mongoose.Types.ObjectId.isValid(receiverId)) {
        console.error('❌ Invalid receiverId:', receiverId);
        return res.status(400).json({ error: 'Invalid receiverId' });
      }

      if (!text || text.trim().length === 0) {
        console.error('❌ Missing or empty text');
        return res.status(400).json({ error: 'Message text is required' });
      }
  
      // Ensure IDs are consistent between Swift and Node.js
      const chatId = [senderId, receiverId].sort().join('_');
  
      const newMessage = new Message({
        chatId,
        senderId: new mongoose.Types.ObjectId(senderId),
        receiverId: new mongoose.Types.ObjectId(receiverId),
        text: text.trim()
      });
  
      const savedMessage = await newMessage.save();
      console.log('✅ Message saved:', savedMessage);

      const formattedMessage = {
        id: savedMessage._id.toString(),
        chatId: savedMessage.chatId,
        senderId: savedMessage.senderId.toString(),
        receiverId: savedMessage.receiverId.toString(),
        text: savedMessage.text,
        createdAt: savedMessage.createdAt.toISOString()
      };
  
      // Emit to receiver via socket if online
      const targetSocketId = req.onlineUsers?.[receiverId];
      if (targetSocketId) {
        req.io.to(targetSocketId).emit('receive-message', formattedMessage);
        console.log('📩 Message emitted to socket:', targetSocketId);
      }
  
      res.status(201).json(formattedMessage);
    } catch (error) {
      console.error('❌ Error sending message:', error);
      res.status(500).json({ error: 'Server error' });
    }
  };

  exports.getMessages = async (req, res) => {
    try {
      const { userId1, userId2 } = req.params;
      
      // Validate IDs
      if (!userId1 || !mongoose.Types.ObjectId.isValid(userId1)) {
        return res.status(400).json({ error: 'Invalid userId1' });
      }
      
      if (!userId2 || !mongoose.Types.ObjectId.isValid(userId2)) {
        return res.status(400).json({ error: 'Invalid userId2' });
      }
  
      const chatId = [userId1, userId2].sort().join('_');
      console.log('🔍 Fetching messages for chatId:', chatId);

      const messages = await Message.find({ chatId }).sort({ createdAt: 1 });
      console.log(`✅ Found ${messages.length} messages`);
      
      // Format messages to match Swift expectation
      const formattedMessages = messages.map(msg => ({
        id: msg._id.toString(),
        chatId: msg.chatId,
        senderId: msg.senderId.toString(),
        receiverId: msg.receiverId.toString(),
        text: msg.text,
        createdAt: msg.createdAt.toISOString()
      }));
  
      res.status(200).json(formattedMessages);
    } catch (error) {
      console.error('❌ Error fetching messages:', error);
      res.status(500).json({ error: 'Server error' });
    }
  };