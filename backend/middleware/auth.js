const jwt = require("jsonwebtoken");
const User = require("../models/User");
const { isDbConnected } = require("../utils/dbState");
const localDb = require("../utils/localDb");

const JWT_SECRET = process.env.JWT_SECRET || "study_planner_secret_key_2024";

module.exports = async function auth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No token provided" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    const user = isDbConnected()
      ? await User.findById(decoded.id)
      : localDb.findUserById(decoded.id);

    if (!user) {
      return res.status(401).json({ error: "User not found" });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
};
