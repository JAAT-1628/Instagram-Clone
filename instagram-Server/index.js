const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const cookieParser = require('cookie-parser');
const mongoose = require('mongoose');
const socketIo = require('socket.io');
const http = require('http');

const authRouter = require('./routes/authRouter');
const postRouter = require('./routes/postRouter');
const userRouter = require('./routes/userRouter');
const notificationRouter = require('./routes/notificationRouter');
const messageRouter = require('./routes/messageRouter');
const chatRouter = require('./routes/chatRoutes');

const Message = require('./models/messageModel');
const Chat = require('./models/chatModel');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// ✅ Track connected users
const onlineUsers = {};

io.on('connection', (socket) => {
  console.log('🔌 User connected:', socket.id);

  // ✅ Store socket ID per user
  socket.on('join', (userId) => {
    onlineUsers[userId] = socket.id;
    console.log(`✅ User ${userId} joined with socket ID ${socket.id}`);
  });

  // ✅ Handle incoming message and forward to receiver
  socket.on('send-message', async (data) => {
    try {
      const { senderId, receiverId, text } = data;
      console.log('📨 Received message:', { senderId, receiverId, text });
      
      if (!senderId || !receiverId || !text) {
        console.error('❌ Missing message data:', { senderId, receiverId, text });
        return;
      }

      const chatId = [senderId, receiverId].sort().join('_');

      const newMessage = new Message({
        chatId,
        senderId: new mongoose.Types.ObjectId(senderId),
        receiverId: new mongoose.Types.ObjectId(receiverId),
        text
      });

      const savedMessage = await newMessage.save();
      console.log('✅ Message saved:', savedMessage);
      
      // Update chat's lastMessage and lastMessageAt
      const chat = await Chat.findOne({
        participants: { 
          $all: [
            new mongoose.Types.ObjectId(senderId),
            new mongoose.Types.ObjectId(receiverId)
          ]
        }
      });

      if (chat) {
        chat.lastMessage = text;
        chat.lastMessageAt = savedMessage.createdAt;
        chat.unreadCount.set(receiverId, (chat.unreadCount.get(receiverId) || 0) + 1);
        await chat.save();
        console.log('✅ Chat updated with new message');
      }
      
      // Format message for client
      const formattedMessage = {
        id: savedMessage._id.toString(),
        chatId: savedMessage.chatId,
        senderId: savedMessage.senderId.toString(),
        receiverId: savedMessage.receiverId.toString(),
        text: savedMessage.text,
        createdAt: savedMessage.createdAt.toISOString()
      };

      const receiverSocketId = onlineUsers[receiverId];
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('receive-message', formattedMessage);
        console.log(`📩 Sent message to user ${receiverId}`);
      }
    } catch (err) {
      console.error('❌ Error handling send-message:', err);
    }
  });

  // ✅ Clean up on disconnect
  socket.on('disconnect', () => {
    for (const [userId, id] of Object.entries(onlineUsers)) {
      if (id === socket.id) {
        delete onlineUsers[userId];
        break;
      }
    }
    console.log('👋 User disconnected:', socket.id);
  });
});

// ✅ Global middleware
app.use(cors());
app.use(helmet());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// ✅ Inject socket + online users into every request
app.use((req, res, next) => {
  req.io = io;
  req.onlineUsers = onlineUsers;
  next();
});

// ✅ Register routes
app.use('/api/auth', authRouter);
app.use('/api/post', postRouter);
app.use('/api/user', userRouter);
app.use('/api/notification', notificationRouter);
app.use('/api/messages', messageRouter);
app.use('/api/chat', chatRouter);

// ✅ Connect to DB and start server
mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

server.listen(process.env.PORT || 8000, () => {
  console.log(`🚀 Server started on http://localhost:${process.env.PORT || 8000}`);
});