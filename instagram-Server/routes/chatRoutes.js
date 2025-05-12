const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middlewares/authMiddleware');

// Apply auth middleware to all routes
router.use(authMiddleware);

// Start a new chat or get existing chat
router.post('/start', chatController.createChat);

// Get all chats for the current user
router.get('/list', chatController.getUserChats);

// Mark a chat as read
router.post('/:chatId/read', chatController.markAsRead);

module.exports = router; 