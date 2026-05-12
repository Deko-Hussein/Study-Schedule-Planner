const path = require("path");
const express = require("express");
const cors = require("cors");
require("dotenv").config({ path: path.join(__dirname, ".env") });
const connectDB = require("./config/db.js");
const { isDbConnected } = require("./utils/dbState");
const { DB_PATH } = require("./utils/localDb");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api/auth", require("./routes/auth"));
app.use("/api/users", require("./routes/users"));
app.use("/api/subjects", require("./routes/subjects"));
app.use("/api/schedules", require("./routes/schedules"));
app.use("/api/reminders", require("./routes/reminders"));
app.use("/api/tasks", require("./routes/tasks"));

app.get("/", (req, res) => {
  res.json({
    status: "Study Planner API running",
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);

  res.status(err.status || 500).json({
    error: err.message || "Internal Server Error",
  });
});

const startServer = async () => {
  await connectDB();

  app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);

    if (!isDbConnected()) {
      console.log(`Local data fallback active: ${DB_PATH}`);
    }
  });
};

startServer();
