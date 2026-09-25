const pool = require('../config/database');

// POST /api/reports/found
exports.createFoundReport = async (req, res) => {
  try {
    const finderId = req.user.id;
    const item_id = req.body.item_id || req.body.itemId;
    const tag_id = req.body.tag_id || req.body.tagId;
    const location = req.body.location || req.body.foundLocation;
    const note = req.body.note || req.body.notes;

    let targetItemId = item_id;
    let itemRecord = null;

    if (targetItemId) {
      const [rows] = await pool.query('SELECT * FROM items WHERE id = ?', [targetItemId]);
      if (rows.length > 0) itemRecord = rows[0];
    } else if (tag_id) {
      const [rows] = await pool.query('SELECT * FROM items WHERE tag_id = ?', [tag_id.trim()]);
      if (rows.length > 0) {
        itemRecord = rows[0];
        targetItemId = itemRecord.id;
      }
    }

    if (!targetItemId || !itemRecord) {
      return res.status(404).json({
        success: false,
        message: 'No registered item found matching the provided item ID or Tag ID.',
      });
    }

    const reportLocation = location || 'Campus Security Desk';
    const reportNote = note || 'Item found and submitted via Traceback report.';

    // Insert into found_reports
    const [reportResult] = await pool.query(
      'INSERT INTO found_reports (item_id, finder_id, location, note) VALUES (?, ?, ?, ?)',
      [targetItemId, finderId, reportLocation, reportNote]
    );

    // Update item status and location
    await pool.query(
      'UPDATE items SET status = "found", last_detected_location = ? WHERE id = ?',
      [reportLocation, targetItemId]
    );

    // Notify the owner of the item
    await pool.query(
      'INSERT INTO notifications (user_id, item_id, title, message) VALUES (?, ?, ?, ?)',
      [
        itemRecord.owner_id,
        targetItemId,
        'Item Located!',
        `Your item "${itemRecord.name}" was spotted at ${reportLocation}. Note: ${reportNote}`,
      ]
    );

    // Log activity for owner
    await pool.query(
      'INSERT INTO activity (user_id, item_id, action, description) VALUES (?, ?, ?, ?)',
      [
        itemRecord.owner_id,
        targetItemId,
        'ITEM_FOUND_REPORT',
        `Finder reported finding ${itemRecord.name} at ${reportLocation}`,
      ]
    );

    // Log activity for finder
    await pool.query(
      'INSERT INTO activity (user_id, item_id, action, description) VALUES (?, ?, ?, ?)',
      [
        finderId,
        targetItemId,
        'FOUND_REPORT_SUBMITTED',
        `Submitted found report for ${itemRecord.name} (Tag: ${itemRecord.tag_id})`,
      ]
    );

    const [newReport] = await pool.query('SELECT * FROM found_reports WHERE id = ?', [reportResult.insertId]);

    return res.status(201).json({
      success: true,
      message: 'Found report recorded successfully. Owner has been notified.',
      report: newReport[0],
      item: {
        ...itemRecord,
        status: 'found',
        last_detected_location: reportLocation,
      },
    });
  } catch (error) {
    console.error('[CreateFoundReport Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error recording found report.',
      error: error.message,
    });
  }
};

// GET /api/reports/found
exports.getFoundReports = async (req, res) => {
  try {
    const userId = req.user.id;

    // Return reports for items owned by user OR submitted by user as finder
    const [rows] = await pool.query(
      `SELECT r.*, i.name as item_name, i.tag_id, i.category, u.name as finder_name
       FROM found_reports r
       JOIN items i ON r.item_id = i.id
       LEFT JOIN users u ON r.finder_id = u.id
       WHERE i.owner_id = ? OR r.finder_id = ?
       ORDER BY r.created_at DESC`,
      [userId, userId]
    );

    return res.status(200).json({
      success: true,
      count: rows.length,
      reports: rows,
    });
  } catch (error) {
    console.error('[GetFoundReports Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving found reports.',
      error: error.message,
    });
  }
};
