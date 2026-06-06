const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const crypto = require('crypto');
const tls = require('tls');
const { isLocalDataMode, localDataFallbackEnabled, setLocalDataMode } = require('./lib/dataMode');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;
const RETRY_DELAY_MS = Number(process.env.MONGO_RETRY_DELAY_MS) || 3000;
const MONGO_SERVER_SELECTION_TIMEOUT_MS =
  Number(process.env.MONGO_SERVER_SELECTION_TIMEOUT_MS) || 3000;
const MONGO_ADDRESS_FAMILY =
  process.env.MONGO_ADDRESS_FAMILY === '4' || process.env.MONGO_ADDRESS_FAMILY === '6'
    ? Number(process.env.MONGO_ADDRESS_FAMILY)
    : undefined;
const MONGO_USE_STABLE_API = process.env.MONGO_USE_STABLE_API !== 'false';
const MONGO_TLS_LEGACY_SERVER_CONNECT =
  process.env.MONGO_TLS_LEGACY_SERVER_CONNECT === 'true';
const MAX_RECONNECT_ATTEMPTS =
  Number(process.env.MONGO_MAX_RECONNECT_ATTEMPTS) > 0
    ? Number(process.env.MONGO_MAX_RECONNECT_ATTEMPTS)
    : Infinity;
const adminRoutes = require("./routes/admin");

let mongoConnectPromise = null;
let reconnectTimer = null;
let serverStarted = false;
let mongoConfigErrorLogged = false;
let lastMongoError = null;
let lastMongoErrorSignature = null;
let mongoDisconnectedLogged = false;
let localDataModeLogged = false;
let reconnectAttempts = 0;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

mongoose.set('strictQuery', false);
mongoose.set('bufferCommands', false);

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

function getMongoOptions() {
  const options = {
    appName: 'study-schedule-planner',
    serverSelectionTimeoutMS: MONGO_SERVER_SELECTION_TIMEOUT_MS,
  };

  if (MONGO_ADDRESS_FAMILY) {
    options.family = MONGO_ADDRESS_FAMILY;
  }

  if (MONGO_USE_STABLE_API) {
    options.serverApi = { version: '1' };
  }

  if (MONGO_TLS_LEGACY_SERVER_CONNECT) {
    options.secureContext = tls.createSecureContext({
      secureOptions: crypto.constants.SSL_OP_LEGACY_SERVER_CONNECT,
    });
  }

  return options;
}

function classifyMongoError(err) {
  const configError = getMongoConfigError();
  if (configError) {
    return {
      category: 'configuration',
      summary: configError,
      code: 'MONGO_CONFIG_ERROR',
    };
  }

  const message = err?.message || 'Unknown MongoDB connection error';
  const code = err?.cause?.code || err?.code || 'UNKNOWN';
  const normalized = message.toLowerCase();

  if (
    normalized.includes('tlsv1 alert internal error') ||
    normalized.includes('err_ssl_tlsv1_alert_internal_error')
  ) {
    return {
      category: 'tls',
      summary:
        'MongoDB Atlas rejected the TLS handshake. This is usually caused by Atlas IP access rules, a VPN/proxy/firewall, or blocked outbound traffic on port 27017 rather than an Express route bug.',
      code,
    };
  }

  if (
    normalized.includes("isn't whitelisted") ||
    normalized.includes('ip whitelist') ||
    normalized.includes('access list')
  ) {
    return {
      category: 'access-list',
      summary:
        'MongoDB Atlas denied the connection from this machine. Add your current public IP to the Atlas IP Access List or temporarily allow 0.0.0.0/0 for testing.',
      code,
    };
  }

  if (
    normalized.includes('querysrv etimeout') ||
    normalized.includes('querysrv enotfound') ||
    normalized.includes('enotfound') ||
    normalized.includes('getaddrinfo')
  ) {
    return {
      category: 'dns',
      summary:
        'The Atlas SRV DNS lookup timed out or could not be resolved. Check your internet connection, DNS settings, VPN, or whether your network blocks SRV lookups.',
      code,
    };
  }

  if (
    normalized.includes('bad auth') ||
    normalized.includes('authentication failed') ||
    normalized.includes('auth error')
  ) {
    return {
      category: 'authentication',
      summary:
        'MongoDB authentication failed. Recheck the Atlas database username, password, and whether special characters in the password are URL-encoded.',
      code,
    };
  }

  if (
    normalized.includes('econnrefused') ||
    normalized.includes('etimedout') ||
    normalized.includes('socket hang up')
  ) {
    return {
      category: 'network',
      summary:
        'The MongoDB connection could not be opened over the network. Check firewall rules, VPN/proxy settings, and whether your network allows outbound traffic to Atlas.',
      code,
    };
  }

  return {
    category: 'unknown',
    summary: message,
    code,
  };
}

function rememberMongoError(err) {
  const details = classifyMongoError(err);
  const hints = [];

  if (details.category === 'tls' || details.category === 'access-list') {
    hints.push('Add your current public IP to MongoDB Atlas Network Access.');
    hints.push('If you are on VPN, school Wi-Fi, office Wi-Fi, or a proxy, try a phone hotspot.');
  }

  if (details.category === 'tls') {
    hints.push('Set MONGO_ADDRESS_FAMILY=4 in backend/.env and restart the backend.');
    hints.push(
      'If the network is doing TLS interception, set MONGO_TLS_LEGACY_SERVER_CONNECT=true only for testing.'
    );
  }

  if (details.category === 'authentication') {
    hints.push('Recheck the Atlas database username and password in backend/.env.');
  }

  if (details.category === 'dns') {
    hints.push('Try a different network such as a phone hotspot to rule out local DNS filtering.');
    hints.push('If your DNS blocks SRV lookups, use the non-SRV Atlas connection string format in backend/.env.');
  }

  if (localDataFallbackEnabled) {
    hints.push('Local fallback mode is available, so the app can keep working with data stored in backend/.local-data.json.');
  }

  lastMongoError = {
    ...details,
    hints,
    rawMessage: err?.message || 'Unknown MongoDB connection error',
    at: new Date().toISOString(),
  };

  return lastMongoError;
}

function logMongoError(err) {
  const details = rememberMongoError(err);
  const signature = `${details.category}:${details.code}:${details.rawMessage}`;

  if (signature === lastMongoErrorSignature) {
    return;
  }

  lastMongoErrorSignature = signature;
  console.error(`MongoDB connection error [${details.category}]: ${details.summary}`);
  if (details.rawMessage && details.rawMessage !== details.summary) {
    console.error(`MongoDB error details: ${details.rawMessage}`);
  }
}

function getDatabaseUnavailableMessage() {
  if (isLocalDataMode()) {
    return null;
  }

  const configError = getMongoConfigError();
  if (configError) {
    return configError;
  }

  return lastMongoError?.summary || 'Database unavailable. Start MongoDB or update backend/.env with a working MONGO_URI.';
}

mongoose.connection.on('connected', () => {
  mongoConnectPromise = null;
  lastMongoError = null;
  lastMongoErrorSignature = null;
  mongoDisconnectedLogged = false;
  localDataModeLogged = false;
  setLocalDataMode(false);
  reconnectAttempts = 0;
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  console.log('MongoDB connected');
});

mongoose.connection.on('error', (err) => {
  logMongoError(err);
});

mongoose.connection.on('disconnected', () => {
  if (!mongoDisconnectedLogged && (mongoose.connection.readyState !== 0 || reconnectAttempts > 0)) {
    console.warn('MongoDB connection disconnected');
    mongoDisconnectedLogged = true;
  }
  mongoConnectPromise = null;

  if (localDataFallbackEnabled) {
    setLocalDataMode(true);
  }

  scheduleReconnect();
});

app.get('/', (req, res) => res.json({ status: 'Study Planner API running' }));
app.get('/api/health', (req, res) => {
  const dbConnected = mongoose.connection.readyState === 1;
  const localMode = isLocalDataMode();
  const configError = getMongoConfigError();
  const serviceAvailable = dbConnected || localMode;

  res.status(serviceAvailable ? 200 : 503).json({
    status: dbConnected ? 'ok' : localMode ? 'fallback' : 'degraded',
    database: dbConnected ? 'connected' : localMode ? 'local-fallback' : 'disconnected',
    error: serviceAvailable ? null : configError || lastMongoError?.summary || null,
    details: dbConnected && !localMode
      ? null
      : {
          mode: localMode ? 'local-fallback' : 'mongo-only',
          category: lastMongoError?.category || (configError ? 'configuration' : 'unknown'),
          code: lastMongoError?.code || (configError ? 'MONGO_CONFIG_ERROR' : null),
          at: lastMongoError?.at || null,
          reconnectAttempts,
          hints: lastMongoError?.hints || [],
        },
  });
});

app.use((req, res, next) => {
  if (req.path === '/' || req.path === '/api/health') {
    return next();
  }

  if (mongoose.connection.readyState !== 1 && !isLocalDataMode()) {
    return res.status(503).json({
      error: getDatabaseUnavailableMessage(),
    });
  }

  next();
});

app.use('/api/auth', require('./routes/auth'));
app.use("/api/admin-auth", require("./routes/adminAuth"));
app.use('/api/users', require('./routes/users'));
app.use('/api/subjects', require('./routes/subjects'));
app.use('/api/schedules', require('./routes/schedules'));
app.use('/api/reminders', require('./routes/reminders'));
app.use('/api/tasks', require('./routes/tasks'));
app.use("/api/admin", adminRoutes);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || 'Internal Server Error' });
});

function scheduleReconnect() {
  if (reconnectTimer || mongoose.connection.readyState === 1) {
    return;
  }

  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.error('MongoDB reconnect attempts exhausted. Waiting for manual restart.');
    return;
  }

  reconnectAttempts += 1;
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

    if (localDataFallbackEnabled) {
      setLocalDataMode(true);
      if (!localDataModeLogged) {
        console.warn('Local fallback mode enabled because MongoDB is not configured.');
        localDataModeLogged = true;
      }
    }

    return;
  }

  if (mongoose.connection.readyState === 1) {
    return;
  }

  if (mongoConnectPromise) {
    return mongoConnectPromise;
  }

  mongoConnectPromise = mongoose.connect(MONGO_URI, getMongoOptions());

  try {
    await mongoConnectPromise;
  } catch (err) {
    logMongoError(err);
    mongoConnectPromise = null;
    if (localDataFallbackEnabled) {
      setLocalDataMode(true);
      if (!localDataModeLogged) {
        console.warn('Local fallback mode enabled. Data will be stored in backend/.local-data.json until MongoDB reconnects.');
        localDataModeLogged = true;
      }
    }
    scheduleReconnect();
  }
}

function startServer() {
  if (!serverStarted) {
    const server = app.listen(PORT, () => {
      serverStarted = true;
      console.log(`Server running on http://localhost:${PORT}`);
      connectToMongo();
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use. Stop the other server or change PORT in backend/.env.`);
        process.exitCode = 1;
        return;
      }

      console.error('Server startup error:', err);
      process.exitCode = 1;
    });
  }
}

startServer();
