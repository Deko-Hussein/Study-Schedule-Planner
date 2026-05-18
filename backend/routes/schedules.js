const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const Schedule = require("../models/Schedule");
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

router.get("/", auth, async (req, res) => {
  try {
    let mongoQuery = { user: req.user._id };

    if (req.query.date) {
      const start = new Date(req.query.date);
      const end = new Date(req.query.date);
      end.setDate(end.getDate() + 1);

      mongoQuery = {
        ...mongoQuery,
        date: {
          $gte: start,
          $lt: end,
        },
      };
    }

    const schedules = isDbConnected()
      ? await Schedule.find(mongoQuery)
          .populate("subject", "name color icon")
          .sort({ date: 1, startTime: 1 })
      : localDb.getSchedulesByUser(req.user._id, req.query.date);

    res.json({ schedules });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/", auth, async (req, res) => {
  try {
    const { subject, title, date, startTime, endTime, notes } = req.body;

    if (!title || !date || !startTime || !endTime) {
      return res.status(400).json({
        error: "Title, date, startTime and endTime are required",
      });
    }

    const schedule = isDbConnected()
      ? await Schedule.create({
          user: req.user._id,
          subject: subject || null,
          title,
          date,
          startTime,
          endTime,
          notes: notes || "",
        })
      : localDb.createSchedule(req.user._id, {
          subject,
          title,
          date,
          startTime,
          endTime,
          notes,
        });

    if (isDbConnected()) {
      await schedule.populate("subject", "name color icon");
    }

    res.status(201).json({ schedule });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch("/:id/complete", auth, async (req, res) => {
  try {
    const schedule = isDbConnected()
      ? await Schedule.findOne({ _id: req.params.id, user: req.user._id })
      : localDb.toggleScheduleComplete(req.user._id, req.params.id);

    if (!schedule) {
      return res.status(404).json({ error: "Schedule not found" });
    }

    if (isDbConnected()) {
      schedule.completed = !schedule.completed;
      await schedule.save();
      await schedule.populate("subject", "name color icon");
    }

    res.json({ schedule });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete("/:id", auth, async (req, res) => {
  try {
    const deleted = isDbConnected()
      ? await Schedule.findOneAndDelete({ _id: req.params.id, user: req.user._id })
      : localDb.deleteSchedule(req.user._id, req.params.id);

    if (!deleted) {
      return res.status(404).json({ error: "Schedule not found" });
    }

    res.json({ message: "Schedule deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
