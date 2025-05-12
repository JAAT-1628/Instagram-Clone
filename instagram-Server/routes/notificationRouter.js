const express = require('express');
const router = express.Router();
const norificationController = require('../controllers/notificationController')

// Create a notification
router.post('/', norificationController.createNotification);

// Get notifications for a user
router.get('/:userId', norificationController.getNotificationsForUser);

module.exports = router;
