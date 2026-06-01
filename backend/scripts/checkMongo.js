const crypto = require('crypto');
const dns = require('dns').promises;
const net = require('net');
const path = require('path');
const tls = require('tls');
const mongoose = require('mongoose');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const MONGO_URI = process.env.MONGO_URI;
const MONGO_SERVER_SELECTION_TIMEOUT_MS =
  Number(process.env.MONGO_SERVER_SELECTION_TIMEOUT_MS) || 8000;
const MONGO_ADDRESS_FAMILY =
  process.env.MONGO_ADDRESS_FAMILY === '4' || process.env.MONGO_ADDRESS_FAMILY === '6'
    ? Number(process.env.MONGO_ADDRESS_FAMILY)
    : undefined;
const MONGO_USE_STABLE_API = process.env.MONGO_USE_STABLE_API !== 'false';
const MONGO_TLS_LEGACY_SERVER_CONNECT =
  process.env.MONGO_TLS_LEGACY_SERVER_CONNECT === 'true';

function getMongoOptions() {
  const options = {
    appName: 'study-schedule-planner-mongo-check',
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

function getMongoUriHost(uri) {
  if (!uri) {
    return null;
  }

  const sanitized = uri.replace(/^mongodb(\+srv)?:\/\//, '');
  const hostPart = sanitized.split('@').pop()?.split('/')[0] || '';
  return hostPart.split(',')[0] || null;
}

function classifyError(message) {
  const normalized = String(message || '').toLowerCase();

  if (normalized.includes('tlsv1 alert internal error')) {
    return 'Atlas or a network device rejected the MongoDB TLS session after the socket opened.';
  }

  if (
    normalized.includes("isn't whitelisted") ||
    normalized.includes('ip whitelist') ||
    normalized.includes('access list')
  ) {
    return 'Atlas IP access rules are blocking this machine.';
  }

  if (
    normalized.includes('querysrv etimeout') ||
    normalized.includes('querysrv enotfound') ||
    normalized.includes('enotfound') ||
    normalized.includes('getaddrinfo')
  ) {
    return 'SRV DNS lookup failed before MongoDB could connect.';
  }

  if (
    normalized.includes('bad auth') ||
    normalized.includes('authentication failed') ||
    normalized.includes('auth error')
  ) {
    return 'Atlas credentials were rejected.';
  }

  if (
    normalized.includes('econnrefused') ||
    normalized.includes('etimedout') ||
    normalized.includes('socket hang up')
  ) {
    return 'The network path to Atlas is blocked or timing out.';
  }

  return 'MongoDB returned an unclassified connection error.';
}

function testTcp(host, port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host, port });
    const done = (result) => {
      socket.removeAllListeners();
      socket.destroy();
      resolve(result);
    };

    socket.setTimeout(8000, () => done({ ok: false, detail: 'timeout' }));
    socket.on('connect', () => done({ ok: true, detail: 'connected' }));
    socket.on('error', (err) => done({ ok: false, detail: err.message }));
  });
}

function testTls(host, port) {
  return new Promise((resolve) => {
    const socket = tls.connect(
      { host, port, servername: host, rejectUnauthorized: true },
      () => {
        const cipher = socket.getCipher();
        const protocol = socket.getProtocol();
        socket.end();
        resolve({
          ok: true,
          detail: `${protocol} ${cipher ? cipher.standardName || cipher.name : 'unknown-cipher'}`,
        });
      }
    );

    const done = (result) => {
      socket.removeAllListeners();
      socket.destroy();
      resolve(result);
    };

    socket.setTimeout(8000, () => done({ ok: false, detail: 'timeout' }));
    socket.on('error', (err) => done({ ok: false, detail: err.message }));
  });
}

async function main() {
  if (!MONGO_URI) {
    console.error('MONGO_URI is missing in backend/.env');
    process.exit(1);
  }

  const host = getMongoUriHost(MONGO_URI);
  if (!host) {
    console.error('Could not parse the MongoDB host from MONGO_URI.');
    process.exit(1);
  }

  console.log(`Mongo URI host: ${host}`);
  console.log(`Address family: ${MONGO_ADDRESS_FAMILY || 'default'}`);
  console.log(`Stable API: ${MONGO_USE_STABLE_API ? 'enabled' : 'disabled'}`);
  console.log(
    `Legacy TLS connect: ${MONGO_TLS_LEGACY_SERVER_CONNECT ? 'enabled' : 'disabled'}`
  );
  console.log('');

  let srvRecords = [];
  if (MONGO_URI.startsWith('mongodb+srv://')) {
    try {
      srvRecords = await dns.resolveSrv(`_mongodb._tcp.${host}`);
      console.log(`SRV lookup ok (${srvRecords.length} host(s))`);
      srvRecords.forEach((record) => {
        console.log(`  - ${record.name}:${record.port}`);
      });
    } catch (err) {
      console.log(`SRV lookup failed: ${err.message}`);
    }
  }

  const tcpTargets = srvRecords.length > 0 ? srvRecords : [{ name: host, port: 27017 }];
  console.log('');

  for (const target of tcpTargets.slice(0, 3)) {
    const tcp = await testTcp(target.name, target.port);
    console.log(`TCP ${target.name}:${target.port} -> ${tcp.ok ? 'ok' : `failed (${tcp.detail})`}`);
  }

  const tlsResults = [];
  for (const target of tcpTargets.slice(0, 3)) {
    const tlsResult = await testTls(target.name, target.port);
    tlsResults.push({ target, tlsResult });
    console.log(
      `TLS ${target.name}:${target.port} -> ${
        tlsResult.ok ? 'ok' : `failed (${tlsResult.detail})`
      }`
    );
  }

  console.log('');
  if (tlsResults.some((entry) => entry.tlsResult.ok) && tlsResults.some((entry) => !entry.tlsResult.ok)) {
    console.log(
      'Mixed TLS result detected: some Atlas shard hosts accept TLS while others reject it.'
    );
    console.log(
      'That usually points to an Atlas-side issue, a partial network block, or inconsistent routing between this machine and the cluster.'
    );
    console.log('');
  }

  try {
    await mongoose.connect(MONGO_URI, getMongoOptions());
    console.log('Mongoose connect -> ok');
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.log(`Mongoose connect -> failed (${classifyError(err.message)})`);
    console.log(err.message);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
