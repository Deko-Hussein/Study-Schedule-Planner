let dbConnected = false;

const setDbConnected = (value) => {
  dbConnected = Boolean(value);
};

const isDbConnected = () => dbConnected;

module.exports = {
  setDbConnected,
  isDbConnected,
};
