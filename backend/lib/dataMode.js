const forceLocalDataMode = process.env.FORCE_LOCAL_DATA_MODE === 'true';
const localDataFallbackEnabled = forceLocalDataMode || process.env.LOCAL_DATA_FALLBACK !== 'false';

let localDataMode = forceLocalDataMode;

function isLocalDataMode() {
  return localDataMode;
}

function setLocalDataMode(enabled) {
  localDataMode = forceLocalDataMode || (localDataFallbackEnabled && Boolean(enabled));
  return localDataMode;
}

module.exports = {
  forceLocalDataMode,
  isLocalDataMode,
  localDataFallbackEnabled,
  setLocalDataMode,
};
