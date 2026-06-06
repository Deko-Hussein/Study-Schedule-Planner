const express = require("express");
const User = require("../models/User");
const Task = require("../models/Task");
const Schedule = require("../models/Schedule");
const Subject = require("../models/Subject");
const auth = require("../middleware/auth");
const adminOnly = require("../middleware/admin");

const router = express.Router();

router.use(auth);
router.use(adminOnly);

router.get("/dashboard", async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: "student" });
    const totalTasks = await Task.countDocuments();
    const completedTasks = await Task.countDocuments({ completed: true });
    const pendingTasks = await Task.countDocuments({ completed: false });
    const totalSchedules = await Schedule.countDocuments();
    const totalSubjects = await Subject.countDocuments();
    const totalHistory = completedTasks;
    const totalReminders = await User.countDocuments({ role: "student" });

    res.json({
      totalUsers,
      totalTasks,
      completedTasks,
      pendingTasks,
      totalSchedules,
      totalSubjects,
      totalHistory,
      totalReminders,
    });
  } catch (error) {
    res.status(500).json({ message: "Failed to load dashboard data" });
  }
});

router.get("/users", async (req, res) => {
  try {
    const users = await User.find({ role: "student" }).select("-password");
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: "Failed to load users" });
  }
});

router.patch("/users/:id/status", async (req, res) => {
  try {
    const { status } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    ).select("-password");

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: "Failed to update user status" });
  }
});

router.delete("/users/:id", async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Failed to delete user" });
  }
});

router.get("/tasks", async (req, res) => {
  try {
    const tasks = await Task.find()
      .populate("user", "name email")
      .populate("subject", "name");

    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: "Failed to load tasks" });
  }
});

router.get("/history", async (req, res) => {
  try {
    const history = await Task.find({ completed: true })
      .populate("user", "name email")
      .populate("subject", "name")
      .sort({ completedAt: -1, updatedAt: -1 });

    res.json(history);
  } catch (error) {
    res.status(500).json({ message: "Failed to load history" });
  }
});

router.get("/reminders", async (req, res) => {
  try {
    const reminders = await User.find({ role: "student" })
      .select("name email notifications status")
      .sort({ createdAt: -1 });

    res.json(reminders);
  } catch (error) {
    res.status(500).json({ message: "Failed to load reminders" });
  }
});

router.get("/schedules", async (req, res) => {
  try {
    const schedules = await Schedule.find()
      .populate("user", "name email")
      .populate("subject", "name");

    res.json(schedules);
  } catch (error) {
    res.status(500).json({ message: "Failed to load schedules" });
  }
});

router.get("/subjects", async (req, res) => {
  try {
    const subjects = await Subject.find().populate("user", "name email");
    res.json(subjects);
  } catch (error) {
    res.status(500).json({ message: "Failed to load subjects" });
  }
});

module.exports = router;
