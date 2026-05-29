const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

// GET /api/reminders  – returns embedded notifications settings from user
router.get('/', auth, async (req, res) => {
  try {
    const reminders = isLocalDataMode()
      ? await localStore.getReminders(req.user._id)
      : req.user.notifications;
    res.json({ reminders });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/reminders  – update reminder time and alert sound
router.put('/', auth, async (req, res) => {
  try {
    const { reminderTime, alertSound } = req.body;
    if (isLocalDataMode()) {
      const reminders = await localStore.updateReminders(req.user._id, {
        ...(reminderTime !== undefined ? { reminderTime } : {}),
        ...(alertSound !== undefined ? { alertSound } : {}),
      });
      return res.json({ reminders });
    }

    const update = {};
    if (reminderTime !== undefined) update['notifications.reminderTime'] = reminderTime;
    if (alertSound !== undefined) update['notifications.alertSound'] = alertSound;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $set: update },
      { new: true }
    );
    res.json({ reminders: user.notifications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
