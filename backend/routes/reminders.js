const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

// GET /api/reminders  – returns embedded notifications settings from user
router.get('/', auth, async (req, res) => {
  try {
    res.json({ reminders: req.user.notifications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/reminders  – update reminder time and alert sound
router.put('/', auth, async (req, res) => {
  try {
    const { reminderTime, alertSound } = req.body;
    const update = {};
    if (reminderTime !== undefined) update['notifications.reminderTime'] = reminderTime;
    if (alertSound !== undefined) update['notifications.alertSound'] = alertSound;

    const user = isDbConnected()
      ? await User.findByIdAndUpdate(
          req.user._id,
          { $set: update },
          { new: true }
        )
      : localDb.updateUser(req.user._id, {
          notifications: {
            ...req.user.notifications,
            ...(reminderTime !== undefined ? { reminderTime } : {}),
            ...(alertSound !== undefined ? { alertSound } : {}),
          },
        });

    res.json({ reminders: user.notifications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
