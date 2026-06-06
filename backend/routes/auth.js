const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { isLocalDataMode } = require('../lib/dataMode');
const localStore = require('../lib/localStore');

const JWT_SECRET = process.env.JWT_SECRET || 'study_planner_secret_key_2024';
const signToken = (id) => jwt.sign({ id }, JWT_SECRET, { expiresIn: '30d' });

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, major } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }

    const existing = isLocalDataMode()
      ? await localStore.findUserByEmail(email)
      : await User.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const user = isLocalDataMode()
      ? await localStore.createUser({ name, email, password, major: major || '' })
      : await User.create({ name, email, password, major: major || '' });
    const token = signToken(user._id);

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

    const user = isLocalDataMode()
      ? await localStore.findUserByEmail(email, { includePassword: true })
      : await User.findOne({ email }).select('+password');
    if (!user) return res.status(401).json({ error: 'No account found with this email address.' });

    const match = isLocalDataMode()
      ? await localStore.comparePassword(user._id, password)
      : await user.comparePassword(password);
    if (!match) return res.status(401).json({ error: 'No account found with this email address.' });

    const token = signToken(user._id);
    res.json({
      token,
      user: isLocalDataMode() ? await localStore.findUserById(user._id) : user,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Login failed' });
  }
});

module.exports = router;
