const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Subject = require('../models/Subject');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

// GET  /api/subjects
router.get('/', auth, async (req, res) => {
  try {
    const subjects = isLocalDataMode()
      ? await localStore.listSubjects(req.user._id)
      : await Subject.find({ user: req.user._id }).sort({ createdAt: -1 });
    res.json({ subjects });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/subjects
router.post('/', auth, async (req, res) => {
  try {
    const { name, color, creditHours, icon } = req.body;
    if (!name) return res.status(400).json({ error: 'Subject name is required' });

    const subject = isLocalDataMode()
      ? await localStore.createSubject(req.user._id, {
          name,
          color,
          creditHours,
          icon,
        })
      : await Subject.create({
          user: req.user._id,
          name,
          color: color || '#4F46E5',
          creditHours: creditHours || 3,
          icon: icon || 'book',
        });
    res.status(201).json({ subject });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/subjects/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const subject = isLocalDataMode()
      ? await localStore.updateSubject(req.user._id, req.params.id, req.body)
      : await Subject.findOneAndUpdate(
          { _id: req.params.id, user: req.user._id },
          { $set: req.body },
          { new: true }
        );
    if (!subject) return res.status(404).json({ error: 'Subject not found' });
    res.json({ subject });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/subjects/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const subject = isLocalDataMode()
      ? await localStore.deleteSubject(req.user._id, req.params.id)
      : await Subject.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!subject) return res.status(404).json({ error: 'Subject not found' });
    res.json({ message: 'Subject deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
