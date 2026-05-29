const localDataFallbackEnabled = process.env.LOCAL_DATA_FALLBACK !== 'false';

let localDataMode = false;

function isLocalDataMode() {
  return localDataMode;
}

function setLocalDataMode(enabled) {
  localDataMode = localDataFallbackEnabled && Boolean(enabled);
  return localDataMode;
}

module.exports = {
  isLocalDataMode,
  localDataFallbackEnabled,
  setLocalDataMode,
};
