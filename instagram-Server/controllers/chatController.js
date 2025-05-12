const Chat = require('../models/chatModel');
const User = require('../models/usersModel');
const mongoose = require('mongoose');

exports.createChat = async (req, res) => {
  try {
    const senderId = req.user?._id || req.user?.id;
    const { receiverId } = req.body;

    console.log('📝 Creating chat between:', { senderId, receiverId });

    if (!senderId || !mongoose.Types.ObjectId.isValid(senderId)) {
      console.error('❌ Invalid senderId:', senderId);
      return res.status(400).json({ error: 'Invalid senderId' });
    }

    if (!receiverId || !mongoose.Types.ObjectId.isValid(receiverId)) {
      console.error('❌ Invalid receiverId:', receiverId);
      return res.status(400).json({ error: 'Invalid receiverId' });
    }

    if (senderId === receiverId) {
      console.error('❌ Cannot create chat with self:', senderId);
      return res.status(400).json({ error: 'Cannot create chat with yourself' });
    }

    // Sort IDs for consistent chat lookup
    const participants = [senderId, receiverId].sort();

    // Check if users exist
    const [sender, receiver] = await Promise.all([
      User.findById(senderId),
      User.findById(receiverId)
    ]);

    if (!sender || !receiver) {
      console.error('❌ User not found:', { sender: !!sender, receiver: !!receiver });
      return res.status(404).json({ error: 'One or both users not found' });
    }

    // Check for existing chat with exactly these participants
    const existingChat = await Chat.findOne({
      participants: { $all: participants, $size: 2 }
    }).populate('participants', 'username profileImage');

    if (existingChat) {
      console.log('✅ Found existing chat:', existingChat._id);
      return res.status(200).json({
        _id: existingChat._id.toString(),
        id: existingChat._id.toString(),
        participants: existingChat.participants.map(p => ({
          _id: p._id.toString(),
          id: p._id.toString(),
          username: p.username,
          profileImage: p.profileImage
        })),
        lastMessage: existingChat.lastMessage || '',
        lastMessageAt: existingChat.lastMessageAt.toISOString(),
        unreadCount: Number(existingChat.unreadCount.get(senderId.toString()) || 0),
        createdAt: existingChat.createdAt.toISOString()
      });
    }

    // Create new chat with initial unread counts
    const unreadCount = new Map([
      [senderId.toString(), 0],
      [receiverId.toString(), 0]
    ]);

    const newChat = await Chat.create({
      participants,
      lastMessage: '',
      lastMessageAt: new Date(),
      unreadCount
    });

    const populatedChat = await Chat.findById(newChat._id)
      .populate('participants', 'username profileImage');

    console.log('✅ Created new chat:', newChat._id);

    res.status(201).json({
      _id: populatedChat._id.toString(),
      id: populatedChat._id.toString(),
      participants: populatedChat.participants.map(p => ({
        _id: p._id.toString(),
        id: p._id.toString(),
        username: p.username,
        profileImage: p.profileImage
      })),
      lastMessage: '',
      lastMessageAt: populatedChat.lastMessageAt.toISOString(),
      unreadCount: 0,
      createdAt: populatedChat.createdAt.toISOString()
    });
  } catch (error) {
    console.error('❌ Error creating chat:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.getUserChats = async (req, res) => {
  try {
    const userId = req.user?._id || req.user?.id;
    
    console.log('📝 Fetching chats for user:', userId);

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      console.error('❌ Invalid userId:', userId);
      return res.status(400).json({ error: 'Invalid userId' });
    }

    const chats = await Chat.find({
      participants: userId
    })
    .sort({ lastMessageAt: -1 })
    .populate('participants', 'username profileImage');

    console.log(`✅ Found ${chats.length} chats for user:`, userId);

    const formattedChats = chats.map(chat => ({
      _id: chat._id.toString(),
      id: chat._id.toString(),
      participants: chat.participants.map(p => ({
        _id: p._id.toString(),
        id: p._id.toString(),
        username: p.username,
        profileImage: p.profileImage
      })),
      lastMessage: chat.lastMessage || '',
      lastMessageAt: chat.lastMessageAt.toISOString(),
      unreadCount: Number(chat.unreadCount.get(userId.toString()) || 0),
      createdAt: chat.createdAt.toISOString()
    }));

    res.status(200).json(formattedChats);
  } catch (error) {
    console.error('❌ Error fetching chats:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update last message and unread count
exports.updateChat = async (chatId, messageId, senderId) => {
  try {
    const chat = await Chat.findById(chatId);
    if (!chat) {
      console.error('❌ Chat not found:', chatId);
      return;
    }

    // Update last message
    chat.lastMessage = messageId;
    chat.lastMessageAt = new Date();

    // Increment unread count for all participants except sender
    chat.participants.forEach(participantId => {
      if (participantId.toString() !== senderId.toString()) {
        chat.unreadCount.set(
          participantId.toString(),
          (chat.unreadCount.get(participantId.toString()) || 0) + 1
        );
      }
    });

    await chat.save();
    console.log('✅ Chat updated:', chatId);
  } catch (error) {
    console.error('❌ Error updating chat:', error);
  }
};

// Mark chat as read
exports.markAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user?._id || req.user?.id;

    if (!chatId || !mongoose.Types.ObjectId.isValid(chatId)) {
      return res.status(400).json({ error: 'Invalid chatId' });
    }

    const chat = await Chat.findById(chatId);
    if (!chat) {
      return res.status(404).json({ error: 'Chat not found' });
    }

    // Reset unread count for the user
    chat.unreadCount.set(userId.toString(), 0);
    await chat.save();
    console.log('✅ Chat marked as read:', chatId);

    res.status(200).json({ message: 'Chat marked as read' });
  } catch (error) {
    console.error('❌ Error marking chat as read:', error);
    res.status(500).json({ error: 'Server error' });
  }
}; 