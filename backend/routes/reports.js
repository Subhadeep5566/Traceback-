const express = require('express');
const router = express.Router();
const reportsController = require('../controllers/reportsController');
const authenticateToken = require('../middleware/auth');

router.post('/found', authenticateToken, reportsController.createFoundReport);
router.get('/found', authenticateToken, reportsController.getFoundReports);

module.exports = router;
