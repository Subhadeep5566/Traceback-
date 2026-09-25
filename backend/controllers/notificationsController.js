const pool = require('../config/database');

// GET /api/notifications
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(
      `SELECT n.*, i.name as item_name, i.tag_id
       FROM notifications n
       LEFT JOIN items i ON n.item_id = i.id
       WHERE n.user_id = ?
       ORDER BY n.created_at DESC`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      notifications: rows,
    });
  } catch (error) {
    console.error('[GetNotifications Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving notifications.',
      error: error.message,
    });
  }
};

// PUT /api/notifications/:id/read
exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const notifId = req.params.id;

    const [result] = await pool.query(
      'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [notifId, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found or access denied.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read.',
    });
  } catch (error) {
    console.error('[MarkAsRead Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating notification.',
      error: error.message,
    });
  }
};
