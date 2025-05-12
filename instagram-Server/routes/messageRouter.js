const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const authMiddleware = require('../middlewares/authMiddleware');

// Apply auth middleware to all routes
router.use(authMiddleware);

router.post('/', messageController.sendMessage);
router.get('/:userId1/:userId2', messageController.getMessages);

module.exports = router;