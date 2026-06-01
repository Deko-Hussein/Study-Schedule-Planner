const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Task = require('../models/Task');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

// GET /api/tasks  – optional ?completed=true|false filter
router.get('/', auth, async (req, res) => {
  try {
    const tasks = isLocalDataMode()
      ? await localStore.listTasks(
          req.user._id,
          req.query.completed !== undefined ? req.query.completed === 'true' : undefined
        )
      : await Task.find({
          user: req.user._id,
          ...(req.query.completed !== undefined
            ? { completed: req.query.completed === 'true' }
            : {}),
        })
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
    const { subject, title, description, category, dueDate, priority } = req.body;
    if (!title) return res.status(400).json({ error: 'Task title is required' });

    const task = isLocalDataMode()
      ? await localStore.createTask(req.user._id, {
          subject,
          title,
          description,
          category,
          dueDate,
          priority,
        })
      : await Task.create({
          user: req.user._id,
          subject, title,
          description: description || '',
          category: category || 'Other',
          dueDate: dueDate || null,
          priority: priority || 'medium',
        });
    if (!isLocalDataMode()) {
      await task.populate('subject', 'name color icon');
    }
    res.status(201).json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/tasks/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const task = isLocalDataMode()
      ? await localStore.updateTask(req.user._id, req.params.id, req.body)
      : await Task.findOneAndUpdate(
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
    const task = isLocalDataMode()
      ? await localStore.toggleTaskComplete(req.user._id, req.params.id)
      : await Task.findOne({ _id: req.params.id, user: req.user._id });
    if (!task) return res.status(404).json({ error: 'Task not found' });
    if (!isLocalDataMode()) {
      task.completed = !task.completed;
      task.completedAt = task.completed ? new Date() : null;
      await task.save();
    }
    res.json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/tasks/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const task = isLocalDataMode()
      ? await localStore.deleteTask(req.user._id, req.params.id)
      : await Task.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!task) return res.status(404).json({ error: 'Task not found' });
    res.json({ message: 'Task deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/tasks/history  – completed tasks sorted by completedAt
router.get('/history', auth, async (req, res) => {
  try {
    const tasks = isLocalDataMode()
      ? await localStore.listTaskHistory(req.user._id)
      : await Task.find({ user: req.user._id, completed: true })
          .populate('subject', 'name color icon')
          .sort({ completedAt: -1 })
          .limit(50);
    res.json({ tasks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
