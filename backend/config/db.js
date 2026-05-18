const mongoose = require("mongoose");
const { setDbConnected } = require("../utils/dbState");

mongoose.set("bufferCommands", false);

const connectDB = async () => {
  const allowFallback = process.env.ALLOW_FILE_DB_FALLBACK !== "false";

  try {
    if (!process.env.MONGO_URI) {
      throw new Error(
        "MONGO_URI is missing. Check that backend/.env exists and contains MONGO_URI."
      );
    }

    await mongoose.connect(process.env.MONGO_URI);
    setDbConnected(true);
    console.log("MongoDB connected");
    return true;
  } catch (error) {
    setDbConnected(false);

    if (!allowFallback) {
      console.error("MongoDB error:", error.message);
      process.exit(1);
    }

    console.warn("MongoDB unavailable, using local file storage fallback.");
    console.warn(`Reason: ${error.message}`);
    return false;
  }
};

module.exports = connectDB;
