const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Task = require('../models/Task');

// GET /api/tasks  – optional ?completed=true|false filter
router.get('/', auth, async (req, res) => {
  try {
    const query = { user: req.user._id };
    if (req.query.completed !== undefined) {
      query.completed = req.query.completed === 'true';
    }
    const tasks = await Task.find(query)
      .populate('subject', 'name color icon')
      .sort({ dueDate: 1, createdAt: -1 });
    res.json({ tasks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/tasks
router.post('/', auth, async (req, res) => {
  try {
    const { subject, title, description, dueDate, priority } = req.body;
    if (!title) return res.status(400).json({ error: 'Task title is required' });

    const task = await Task.create({
      user: req.user._id,
      subject, title,
      description: description || '',
      dueDate: dueDate || null,
      priority: priority || 'medium',
    });
    await task.populate('subject', 'name color icon');
    res.status(201).json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/tasks/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { $set: req.body },
      { new: true }
    ).populate('subject', 'name color icon');
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /api/tasks/:id/complete  – toggle completed
router.patch('/:id/complete', auth, async (req, res) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, user: req.user._id });
    if (!task) return res.status(404).json({ error: 'Task not found' });
    task.completed = !task.completed;
    task.completedAt = task.completed ? new Date() : null;
    await task.save();
    res.json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/tasks/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json({ message: 'Task deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/tasks/history  – completed tasks sorted by completedAt
router.get('/history', auth, async (req, res) => {
  try {
    const tasks = await Task.find({ user: req.user._id, completed: true })
      .populate('subject', 'name color icon')
      .sort({ completedAt: -1 })
      .limit(50);
    res.json({ tasks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
