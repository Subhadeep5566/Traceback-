const express = require('express');
const router = express.Router();
const itemsController = require('../controllers/itemsController');
const authenticateToken = require('../middleware/auth');

router.get('/', authenticateToken, itemsController.getItems);
router.post('/', authenticateToken, itemsController.createItem);
router.get('/:id', authenticateToken, itemsController.getItemById);
router.put('/:id', authenticateToken, itemsController.updateItem);
router.delete('/:id', authenticateToken, itemsController.deleteItem);
router.put('/:id/lost', authenticateToken, itemsController.markLost);
router.put('/:id/found', authenticateToken, itemsController.markFound);

module.exports = router;
