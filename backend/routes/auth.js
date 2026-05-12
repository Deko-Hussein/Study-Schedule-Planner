const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

const JWT_SECRET = process.env.JWT_SECRET || 'study_planner_secret_key_2024';
const signToken = (id) => jwt.sign({ id }, JWT_SECRET, { expiresIn: '30d' });

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, major } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }

    let existing;

    if (isDbConnected()) {
      existing = await User.findOne({ email });
    } else {
      existing = localDb.findUserByEmail(email);
    }

    if (existing) return res.status(409).json({ error: 'Email already registered' });

    let user;

    if (isDbConnected()) {
      user = await User.create({ name, email, password, major: major || '' });
      user = user.toJSON();
    } else {
      user = localDb.createUser({ name, email, password, major: major || '' });
    }

    const token = signToken(user._id.toString());

    res.status(201).json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    let user;

    if (isDbConnected()) {
      user = await User.findOne({ email }).select("+password");
    } else {
      user = localDb.findUserByEmail(email, { includePassword: true });
    }

    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const match = isDbConnected()
      ? await user.comparePassword(password)
      : localDb.comparePassword(password, user.password);

    if (!match) return res.status(401).json({ error: 'Invalid credentials' });

    const token = signToken(user._id.toString());
    res.json({ token, user: isDbConnected() ? user.toJSON() : localDb.findUserById(user._id) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Login failed' });
  }
});

module.exports = router;
