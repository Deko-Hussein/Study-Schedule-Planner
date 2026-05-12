const express = require("express");
const router = express.Router();

const auth = require("../middleware/auth");
const User = require("../models/User");
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

// GET /api/users/me
router.get("/me", auth, async (req, res) => {
  try {
    res.json({
      user: req.user,
    });
  } catch (err) {
    res.status(500).json({
      error: err.message,
    });
  }
});

// PUT /api/users/me
router.put("/me", auth, async (req, res) => {
  try {
    const allowed = ["name", "major", "avatar", "notifications"];
    const updates = {};

    allowed.forEach((field) => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });

    const updatedUser = isDbConnected()
      ? await User.findByIdAndUpdate(
          req.user._id,
          { $set: updates },
          {
            new: true,
            runValidators: true,
          }
        )
      : localDb.updateUser(req.user._id, updates);

    res.json({
      user: updatedUser,
    });
  } catch (err) {
    res.status(500).json({
      error: err.message,
    });
  }
});

// PUT /api/users/me/password
router.put("/me/password", auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        error: "Current password and new password are required",
      });
    }

    const user = isDbConnected()
      ? await User.findById(req.user._id).select("+password")
      : localDb.findUserById(req.user._id, { includePassword: true });

    if (!user) {
      return res.status(404).json({
        error: "User not found",
      });
    }

    const match = isDbConnected()
      ? await user.comparePassword(currentPassword)
      : localDb.comparePassword(currentPassword, user.password);

    if (!match) {
      return res.status(400).json({
        error: "Current password is incorrect",
      });
    }

    if (isDbConnected()) {
      user.password = newPassword;
      await user.save();
    } else {
      localDb.updateUserPassword(req.user._id, newPassword);
    }

    res.json({
      message: "Password updated successfully",
    });
  } catch (err) {
    res.status(500).json({
      error: err.message,
    });
  }
});

module.exports = router;
