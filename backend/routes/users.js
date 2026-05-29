const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

// GET /api/users/me  – current user profile
router.get('/me', auth, async (req, res) => {
  try {
    res.json({ user: req.user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/users/me  – update profile (name, major, avatar, notifications)
router.put('/me', auth, async (req, res) => {
  try {
    const allowed = ['name', 'major', 'avatar', 'notifications'];
    const updates = {};
    allowed.forEach(field => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });

    const user = isLocalDataMode()
      ? await localStore.updateUser(req.user._id, updates)
      : await User.findByIdAndUpdate(
          req.user._id,
          { $set: updates },
          { new: true, runValidators: true }
        );
    res.json({ user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/users/me/password  – change password
router.put('/me/password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = isLocalDataMode()
      ? await localStore.findUserById(req.user._id, { includePassword: true })
      : await User.findById(req.user._id).select('+password');
    const match = isLocalDataMode()
      ? await localStore.comparePassword(req.user._id, currentPassword)
      : await user.comparePassword(currentPassword);
    if (!match) return res.status(400).json({ error: 'Current password is incorrect' });

    if (isLocalDataMode()) {
      await localStore.updateUserPassword(req.user._id, newPassword);
    } else {
      user.password = newPassword;
      await user.save();
    }
    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
