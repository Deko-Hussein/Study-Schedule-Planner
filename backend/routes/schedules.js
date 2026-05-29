const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Schedule = require('../models/Schedule');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

// GET /api/schedules  – optional ?date=YYYY-MM-DD filter
router.get('/', auth, async (req, res) => {
  try {
    const schedules = isLocalDataMode()
      ? await localStore.listSchedules(req.user._id, req.query.date)
      : await Schedule.find({
          user: req.user._id,
          ...(req.query.date
            ? (() => {
                const start = new Date(req.query.date);
                const end = new Date(req.query.date);
                end.setDate(end.getDate() + 1);
                return { date: { $gte: start, $lt: end } };
              })()
            : {}),
        })
          .populate('subject', 'name color icon')
          .sort({ date: 1, startTime: 1 });
    res.json({ schedules });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/schedules
router.post('/', auth, async (req, res) => {
  try {
    const { subject, title, date, startTime, endTime, notes } = req.body;
    if (!title || !date || !startTime || !endTime) {
      return res.status(400).json({ error: 'title, date, startTime and endTime are required' });
    }
    const schedule = isLocalDataMode()
      ? await localStore.createSchedule(req.user._id, {
          subject,
          title,
          date,
          startTime,
          endTime,
          notes,
        })
      : await Schedule.create({
          user: req.user._id,
          subject, title, date, startTime, endTime,
          notes: notes || '',
        });
    if (!isLocalDataMode()) {
      await schedule.populate('subject', 'name color icon');
    }
    res.status(201).json({ schedule });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/schedules/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const schedule = isLocalDataMode()
      ? await localStore.updateSchedule(req.user._id, req.params.id, req.body)
      : await Schedule.findOneAndUpdate(
          { _id: req.params.id, user: req.user._id },
          { $set: req.body },
          { new: true }
        ).populate('subject', 'name color icon');
    if (!schedule) return res.status(404).json({ error: 'Schedule not found' });
    res.json({ schedule });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /api/schedules/:id/complete  – toggle completed
router.patch('/:id/complete', auth, async (req, res) => {
  try {
    const schedule = isLocalDataMode()
      ? await localStore.toggleScheduleComplete(req.user._id, req.params.id)
      : await Schedule.findOne({ _id: req.params.id, user: req.user._id });
    if (!schedule) return res.status(404).json({ error: 'Schedule not found' });
    if (!isLocalDataMode()) {
      schedule.completed = !schedule.completed;
      await schedule.save();
    }
    res.json({ schedule });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/schedules/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const schedule = isLocalDataMode()
      ? await localStore.deleteSchedule(req.user._id, req.params.id)
      : await Schedule.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!schedule) return res.status(404).json({ error: 'Schedule not found' });
    res.json({ message: 'Schedule deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
