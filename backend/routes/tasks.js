const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const Task = require("../models/Task");
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

router.get("/history", auth, async (req, res) => {
  try {
    const tasks = isDbConnected()
      ? await Task.find({
          user: req.user._id,
          completed: true,
        })
          .populate("subject", "name color icon")
          .sort({ completedAt: -1 })
          .limit(50)
      : localDb.getTaskHistory(req.user._id);

    res.json({ tasks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/", auth, async (req, res) => {
  try {
    const query = { user: req.user._id };

    if (req.query.completed !== undefined) {
      query.completed = req.query.completed === "true";
    }

    const tasks = isDbConnected()
      ? await Task.find(query)
          .populate("subject", "name color icon")
          .sort({ dueDate: 1, createdAt: -1 })
      : localDb.getTasksByUser(req.user._id, req.query.completed);

    res.json({ tasks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    const { subject, title, description, category, dueDate, priority } = req.body;

    if (!title) {
      return res.status(400).json({ error: "Task title is required" });
    }

    const task = isDbConnected()
      ? await Task.create({
          user: req.user._id,
          subject,
          title,
          description: description || "",
          category: category || "Other",
          dueDate: dueDate || null,
          priority: priority || "medium",
        })
      : localDb.createTask(req.user._id, {
          subject,
          title,
          description,
          category,
          dueDate,
          priority,
        });

    if (isDbConnected()) {
      await task.populate("subject", "name color icon");
    }

    res.status(201).json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put("/:id", auth, async (req, res) => {
  try {
    const task = isDbConnected()
      ? await Task.findOneAndUpdate(
          {
            _id: req.params.id,
            user: req.user._id,
          },
          { $set: req.body },
          { new: true }
        ).populate("subject", "name color icon")
      : localDb.updateTask(req.user._id, req.params.id, req.body);

    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch("/:id/complete", auth, async (req, res) => {
  try {
    const task = isDbConnected()
      ? await Task.findOne({
          _id: req.params.id,
          user: req.user._id,
        })
      : localDb.toggleTaskComplete(req.user._id, req.params.id);

    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    if (isDbConnected()) {
      task.completed = !task.completed;
      task.completedAt = task.completed ? new Date() : null;

      await task.save();
      await task.populate("subject", "name color icon");
    }

    res.json({ task });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete("/:id", auth, async (req, res) => {
  try {
    const task = isDbConnected()
      ? await Task.findOneAndDelete({
          _id: req.params.id,
          user: req.user._id,
        })
      : localDb.deleteTask(req.user._id, req.params.id);

    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    res.json({ message: "Task deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
