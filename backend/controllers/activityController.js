const pool = require('../config/database');

// GET /api/activity
exports.getActivity = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(
      `SELECT a.*, i.name as item_name, i.tag_id
       FROM activity a
       LEFT JOIN items i ON a.item_id = i.id
       WHERE a.user_id = ?
       ORDER BY a.created_at DESC`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      activity: rows,
    });
  } catch (error) {
    console.error('[GetActivity Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving activity log.',
      error: error.message,
    });
  }
};
