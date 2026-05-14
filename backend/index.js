const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;
const RETRY_DELAY_MS = 5000;

let mongoConnectPromise = null;
let reconnectTimer = null;
let serverStarted = false;
let mongoConfigErrorLogged = false;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

mongoose.set('strictQuery', false);
mongoose.set('bufferCommands', false);

mongoose.connection.on('connected', () => {
  mongoConnectPromise = null;
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  console.log('MongoDB connected');
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.warn('MongoDB connection disconnected');
  mongoConnectPromise = null;
  scheduleReconnect();
});

function getMongoConfigError() {
  if (!MONGO_URI) {
    return 'MONGO_URI is missing in backend/.env.';
  }

  const hasPlaceholder =
    MONGO_URI.includes('<db_username>') ||
    MONGO_URI.includes('<db_password>') ||
    MONGO_URI.includes('<cluster-url>') ||
    MONGO_URI.includes('change_me');

  if (hasPlaceholder) {
    return 'MONGO_URI in backend/.env still contains placeholders. Replace <db_username>, <db_password>, and <cluster-url> with your real MongoDB Atlas values.';
  }

  return null;
}

app.get('/', (req, res) => res.json({ status: 'Study Planner API running' }));
app.get('/api/health', (req, res) => {
  const dbConnected = mongoose.connection.readyState === 1;
  const configError = getMongoConfigError();
  res.status(dbConnected ? 200 : 503).json({
    status: dbConnected ? 'ok' : 'degraded',
    database: dbConnected ? 'connected' : 'disconnected',
    error: configError,
  });
});

app.use((req, res, next) => {
  if (req.path === '/' || req.path === '/api/health') {
    return next();
  }

  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({
      error:
        getMongoConfigError() ||
        'Database unavailable. Start MongoDB or update backend/.env with a working MONGO_URI.',
    });
  }

  next();
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/subjects', require('./routes/subjects'));
app.use('/api/schedules', require('./routes/schedules'));
app.use('/api/reminders', require('./routes/reminders'));
app.use('/api/tasks', require('./routes/tasks'));

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || 'Internal Server Error' });
});

function scheduleReconnect() {
  if (reconnectTimer || mongoose.connection.readyState === 1) {
    return;
  }

  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    connectToMongo();
  }, RETRY_DELAY_MS);
}

async function connectToMongo() {
  const configError = getMongoConfigError();
  if (configError) {
    if (!mongoConfigErrorLogged) {
      console.error(`MongoDB configuration error: ${configError}`);
      mongoConfigErrorLogged = true;
    }
    return;
  }

  if (mongoose.connection.readyState === 1) {
    return;
  }

  if (mongoConnectPromise) {
    return mongoConnectPromise;
  }

  mongoConnectPromise = mongoose.connect(MONGO_URI, {
    serverSelectionTimeoutMS: 5000,
  });

  try {
    await mongoConnectPromise;
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    mongoConnectPromise = null;
    scheduleReconnect();
  }
}

function startServer() {
  if (!serverStarted) {
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
    serverStarted = true;
  }

  connectToMongo();
}

startServer();
