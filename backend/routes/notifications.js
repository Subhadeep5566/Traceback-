const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notificationsController');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, notificationsController.getNotifications);
router.put('/:id/read', authenticateToken, notificationsController.markAsRead);

module.exports = router;
