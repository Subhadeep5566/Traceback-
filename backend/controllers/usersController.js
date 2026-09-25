const pool = require('../config/database');

// GET /api/users/profile
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await pool.query(
      'SELECT id, name, email, phone, created_at FROM users WHERE id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User profile not found.',
      });
    }

    return res.status(200).json({
      success: true,
      user: rows[0],
    });
  } catch (error) {
    console.error('[GetProfile Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving profile.',
      error: error.message,
    });
  }
};

// PUT /api/users/profile
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, phone } = req.body;

    const updates = [];
    const values = [];

    if (name) {
      updates.push('name = ?');
      values.push(name.trim());
    }
    if (phone !== undefined) {
      updates.push('phone = ?');
      values.push(phone ? phone.trim() : null);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields provided for update.',
      });
    }

    values.push(userId);
    await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      values
    );

    const [updatedRows] = await pool.query(
      'SELECT id, name, email, phone, created_at FROM users WHERE id = ?',
      [userId]
    );

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      user: updatedRows[0],
    });
  } catch (error) {
    console.error('[UpdateProfile Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating profile.',
      error: error.message,
    });
  }
};
