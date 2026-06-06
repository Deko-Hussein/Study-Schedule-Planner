const express = require("express");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || "study_planner_secret_key_2024";
const signToken = (id) => jwt.sign({ id }, JWT_SECRET, { expiresIn: "30d" });

function getSetupKey(req) {
  return req.headers["x-admin-register-key"] || req.body.setupKey;
}

router.post("/register", async (req, res) => {
  try {
    if (!process.env.ADMIN_REGISTER_KEY) {
      return res.status(500).json({
        message: "ADMIN_REGISTER_KEY is missing in backend/.env",
      });
    }

    if (getSetupKey(req) !== process.env.ADMIN_REGISTER_KEY) {
      return res.status(403).json({ message: "Invalid admin registration key" });
    }

    const { name, email, password, major } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        message: "Name, email and password are required",
      });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const user = await User.create({
      name,
      email,
      password,
      major: major || "",
      role: "admin",
      status: "active",
    });

    const token = signToken(user._id);
    res.status(201).json({ token, user });
  } catch (error) {
    res.status(500).json({ message: error.message || "Admin registration failed" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    const user = await User.findOne({ email, role: "admin" }).select("+password");
    if (!user) {
      return res.status(401).json({ message: "Invalid admin credentials" });
    }

    if (user.status === "blocked") {
      return res.status(403).json({ message: "Admin account is blocked" });
    }

    const match = await user.comparePassword(password);
    if (!match) {
      return res.status(401).json({ message: "Invalid admin credentials" });
    }

    const token = signToken(user._id);
    res.json({ token, user: user.toJSON() });
  } catch (error) {
    res.status(500).json({ message: error.message || "Admin login failed" });
  }
});

module.exports = router;
