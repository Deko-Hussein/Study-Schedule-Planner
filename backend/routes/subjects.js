const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const Subject = require("../models/Subject");
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

router.get("/", auth, async (req, res) => {
  try {
    const subjects = isDbConnected()
      ? await Subject.find({ user: req.user._id }).sort({ createdAt: -1 })
      : localDb.getSubjectsByUser(req.user._id);

    res.json({ subjects });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    const { name, color, creditHours, icon } = req.body;

    if (!name) {
      return res.status(400).json({ error: "Subject name is required" });
    }

    const subject = isDbConnected()
      ? await Subject.create({
          user: req.user._id,
          name,
          color: color || "#4F46E5",
          creditHours: creditHours || 3,
          icon: icon || "book",
        })
      : localDb.createSubject(req.user._id, {
          name,
          color,
          creditHours,
          icon,
        });

    res.status(201).json({ subject });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put("/:id", auth, async (req, res) => {
  try {
    const updates = {};
    ["name", "color", "creditHours", "icon"].forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const subject = isDbConnected()
      ? await Subject.findOneAndUpdate(
          { _id: req.params.id, user: req.user._id },
          { $set: updates },
          { new: true, runValidators: true }
        )
      : localDb.updateSubject(req.user._id, req.params.id, updates);

    if (!subject) {
      return res.status(404).json({ error: "Subject not found" });
    }

    res.json({ subject });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete("/:id", auth, async (req, res) => {
  try {
    const deleted = isDbConnected()
      ? await Subject.findOneAndDelete({ _id: req.params.id, user: req.user._id })
      : localDb.deleteSubject(req.user._id, req.params.id);

    if (!deleted) {
      return res.status(404).json({ error: "Subject not found" });
    }

    res.json({ message: "Subject deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
