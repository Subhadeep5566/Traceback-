const pool = require('../config/database');

// Helper to generate unique tag_id if not provided
function generateTagId(category) {
  const prefix = category ? category.substring(0, 4).toUpperCase() : 'ITEM';
  const rand = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `TB-${prefix}-${rand}`;
}

// GET /api/items
// Returns items for the authenticated user, or allows searching if query params present
exports.getItems = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, search, tag_id } = req.query;

    let query = 'SELECT * FROM items WHERE owner_id = ?';
    const params = [userId];

    if (status) {
      query += ' AND status = ?';
      params.push(status);
    }

    if (tag_id) {
      query += ' AND tag_id = ?';
      params.push(tag_id);
    }

    if (search) {
      query += ' AND (name LIKE ? OR description LIKE ? OR tag_id LIKE ?)';
      const s = `%${search}%`;
      params.push(s, s, s);
    }

    query += ' ORDER BY created_at DESC';

    const [rows] = await pool.query(query, params);

    return res.status(200).json({
      success: true,
      count: rows.length,
      items: rows,
    });
  } catch (error) {
    console.error('[GetItems Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving items.',
      error: error.message,
    });
  }
};

// POST /api/items
exports.createItem = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, category, description, tag_id, last_detected_location, status } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Item name is required.',
      });
    }

    const finalTagId = tag_id && tag_id.trim().length > 0
      ? tag_id.trim()
      : generateTagId(category);

    const itemStatus = status || 'safe';

    const [result] = await pool.query(
      `INSERT INTO items (owner_id, name, category, description, tag_id, status, last_detected_location)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        name.trim(),
        category || 'belonging',
        description || null,
        finalTagId,
        itemStatus,
        last_detected_location || 'Campus Center',
      ]
    );

    const itemId = result.insertId;

    // Log activity
    await pool.query(
      'INSERT INTO activity (user_id, item_id, action, description) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'ITEM_REGISTERED', `Registered ${name.trim()} (Tag: ${finalTagId})`]
    );

    // Create notification
    await pool.query(
      'INSERT INTO notifications (user_id, item_id, title, message) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'Item Secured', `${name.trim()} is now protected on Traceback radar.`]
    );

    const [newItemRows] = await pool.query('SELECT * FROM items WHERE id = ?', [itemId]);

    return res.status(201).json({
      success: true,
      message: 'Item created successfully.',
      item: newItemRows[0],
    });
  } catch (error) {
    console.error('[CreateItem Error]', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        success: false,
        message: 'A device with this Traceback Tag ID already exists.',
      });
    }
    return res.status(500).json({
      success: false,
      message: 'Server error creating item.',
      error: error.message,
    });
  }
};

// GET /api/items/:id
exports.getItemById = async (req, res) => {
  try {
    const userId = req.user.id;
    const itemId = req.params.id;

    const [rows] = await pool.query(
      'SELECT * FROM items WHERE id = ? AND owner_id = ?',
      [itemId, userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item not found or access denied.',
      });
    }

    return res.status(200).json({
      success: true,
      item: rows[0],
    });
  } catch (error) {
    console.error('[GetItemById Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error retrieving item.',
      error: error.message,
    });
  }
};

// PUT /api/items/:id
exports.updateItem = async (req, res) => {
  try {
    const userId = req.user.id;
    const itemId = req.params.id;
    const { name, category, description, tag_id, last_detected_location, status } = req.body;

    // Verify ownership
    const [existing] = await pool.query(
      'SELECT * FROM items WHERE id = ? AND owner_id = ?',
      [itemId, userId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item not found or access denied.',
      });
    }

    const updates = [];
    const values = [];

    if (name !== undefined) {
      updates.push('name = ?');
      values.push(name.trim());
    }
    if (category !== undefined) {
      updates.push('category = ?');
      values.push(category);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      values.push(description);
    }
    if (tag_id !== undefined) {
      updates.push('tag_id = ?');
      values.push(tag_id);
    }
    if (last_detected_location !== undefined) {
      updates.push('last_detected_location = ?');
      values.push(last_detected_location);
    }
    if (status !== undefined) {
      updates.push('status = ?');
      values.push(status);
    }

    if (updates.length > 0) {
      values.push(itemId, userId);
      await pool.query(
        `UPDATE items SET ${updates.join(', ')} WHERE id = ? AND owner_id = ?`,
        values
      );
    }

    const [updated] = await pool.query('SELECT * FROM items WHERE id = ?', [itemId]);

    return res.status(200).json({
      success: true,
      message: 'Item updated successfully.',
      item: updated[0],
    });
  } catch (error) {
    console.error('[UpdateItem Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error updating item.',
      error: error.message,
    });
  }
};

// DELETE /api/items/:id
exports.deleteItem = async (req, res) => {
  try {
    const userId = req.user.id;
    const itemId = req.params.id;

    const [existing] = await pool.query(
      'SELECT * FROM items WHERE id = ? AND owner_id = ?',
      [itemId, userId]
    );

    if (existing.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item not found or access denied.',
      });
    }

    // Delete related notifications and reports first if needed
    await pool.query('DELETE FROM notifications WHERE item_id = ?', [itemId]);
    await pool.query('DELETE FROM found_reports WHERE item_id = ?', [itemId]);
    await pool.query('DELETE FROM activity WHERE item_id = ?', [itemId]);

    await pool.query('DELETE FROM items WHERE id = ? AND owner_id = ?', [itemId, userId]);

    return res.status(200).json({
      success: true,
      message: 'Item deleted successfully.',
    });
  } catch (error) {
    console.error('[DeleteItem Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error deleting item.',
      error: error.message,
    });
  }
};

// PUT /api/items/:id/lost
exports.markLost = async (req, res) => {
  try {
    const userId = req.user.id;
    const itemId = req.params.id;
    const { location, description } = req.body;

    const [rows] = await pool.query(
      'SELECT * FROM items WHERE id = ? AND owner_id = ?',
      [itemId, userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item not found or access denied.',
      });
    }

    const item = rows[0];
    const lostLoc = location || item.last_detected_location || 'Campus';

    await pool.query(
      'UPDATE items SET status = "lost", last_detected_location = ? WHERE id = ? AND owner_id = ?',
      [lostLoc, itemId, userId]
    );

    // Log activity
    await pool.query(
      'INSERT INTO activity (user_id, item_id, action, description) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'REPORTED_LOST', description || `Reported lost near ${lostLoc}`]
    );

    // Create notification
    await pool.query(
      'INSERT INTO notifications (user_id, item_id, title, message) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'Lost Alert Broadcasted', `Radar activated for ${item.name} near ${lostLoc}.`]
    );

    const [updated] = await pool.query('SELECT * FROM items WHERE id = ?', [itemId]);

    return res.status(200).json({
      success: true,
      message: 'Item marked as lost.',
      item: updated[0],
    });
  } catch (error) {
    console.error('[MarkLost Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error marking item lost.',
      error: error.message,
    });
  }
};

// PUT /api/items/:id/found
exports.markFound = async (req, res) => {
  try {
    const userId = req.user.id;
    const itemId = req.params.id;
    const { location } = req.body;

    const [rows] = await pool.query(
      'SELECT * FROM items WHERE id = ? AND owner_id = ?',
      [itemId, userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Item not found or access denied.',
      });
    }

    const item = rows[0];
    const loc = location || item.last_detected_location || 'Campus Safe Zone';

    await pool.query(
      'UPDATE items SET status = "safe", last_detected_location = ? WHERE id = ? AND owner_id = ?',
      [loc, itemId, userId]
    );

    // Log activity
    await pool.query(
      'INSERT INTO activity (user_id, item_id, action, description) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'MARKED_SAFE', `Item secured and marked safe at ${loc}`]
    );

    // Create notification
    await pool.query(
      'INSERT INTO notifications (user_id, item_id, title, message) VALUES (?, ?, ?, ?)',
      [userId, itemId, 'Item Recovered & Safe', `${item.name} status updated to Safe.`]
    );

    const [updated] = await pool.query('SELECT * FROM items WHERE id = ?', [itemId]);

    return res.status(200).json({
      success: true,
      message: 'Item marked as safe/found.',
      item: updated[0],
    });
  } catch (error) {
    console.error('[MarkFound Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Server error marking item found.',
      error: error.message,
    });
  }
};
