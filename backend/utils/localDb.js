const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");

const DB_PATH = path.join(__dirname, "..", "data", "local-db.json");

const DEFAULT_STATE = {
  users: [],
  subjects: [],
  schedules: [],
  tasks: [],
};

const ensureDbFile = () => {
  const dir = path.dirname(DB_PATH);

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  if (!fs.existsSync(DB_PATH)) {
    fs.writeFileSync(DB_PATH, JSON.stringify(DEFAULT_STATE, null, 2));
  }
};

const readState = () => {
  ensureDbFile();

  try {
    const raw = fs.readFileSync(DB_PATH, "utf8");
    const parsed = JSON.parse(raw);

    return {
      ...DEFAULT_STATE,
      ...parsed,
      users: parsed.users || [],
      subjects: parsed.subjects || [],
      schedules: parsed.schedules || [],
      tasks: parsed.tasks || [],
    };
  } catch (error) {
    fs.writeFileSync(DB_PATH, JSON.stringify(DEFAULT_STATE, null, 2));
    return { ...DEFAULT_STATE };
  }
};

const writeState = (state) => {
  ensureDbFile();
  fs.writeFileSync(DB_PATH, JSON.stringify(state, null, 2));
};

const updateState = (mutator) => {
  const state = readState();
  const result = mutator(state);
  writeState(state);
  return result;
};

const clone = (value) => JSON.parse(JSON.stringify(value));

const now = () => new Date().toISOString();

const createId = () => crypto.randomUUID();

const sortByCreatedDesc = (a, b) => {
  return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
};

const sanitizeUser = (user) => {
  if (!user) {
    return null;
  }

  const { password, ...safeUser } = user;
  return clone(safeUser);
};

const findSubjectForUser = (state, userId, subjectId) => {
  if (!subjectId) {
    return null;
  }

  return state.subjects.find(
    (subject) => subject._id === subjectId && subject.user === userId
  );
};

const populateSubject = (item, state, userId) => {
  const copy = clone(item);
  const subject = findSubjectForUser(state, userId, copy.subject);

  if (subject) {
    copy.subject = {
      _id: subject._id,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
    };
  }

  return copy;
};

const parseBool = (value) => {
  if (typeof value === "boolean") {
    return value;
  }

  if (value === "true") {
    return true;
  }

  if (value === "false") {
    return false;
  }

  return undefined;
};

const createUser = ({ name, email, password, major = "" }) =>
  updateState((state) => {
    const timestamp = now();
    const user = {
      _id: createId(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: bcrypt.hashSync(password, 10),
      major,
      avatar: "",
      subscription: "free",
      notifications: {
        reminderTime: "15 Mins",
        alertSound: "Classic Chime",
      },
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.users.push(user);
    return sanitizeUser(user);
  });

const findUserByEmail = (email, { includePassword = false } = {}) => {
  const state = readState();
  const user = state.users.find(
    (entry) => entry.email === String(email).trim().toLowerCase()
  );

  if (!user) {
    return null;
  }

  return includePassword ? clone(user) : sanitizeUser(user);
};

const findUserById = (id, { includePassword = false } = {}) => {
  const state = readState();
  const user = state.users.find((entry) => entry._id === id);

  if (!user) {
    return null;
  }

  return includePassword ? clone(user) : sanitizeUser(user);
};

const comparePassword = (plainPassword, hashedPassword) => {
  return bcrypt.compareSync(plainPassword, hashedPassword);
};

const updateUser = (id, updates) =>
  updateState((state) => {
    const user = state.users.find((entry) => entry._id === id);

    if (!user) {
      return null;
    }

    Object.assign(user, updates, { updatedAt: now() });
    return sanitizeUser(user);
  });

const updateUserPassword = (id, password) =>
  updateState((state) => {
    const user = state.users.find((entry) => entry._id === id);

    if (!user) {
      return null;
    }

    user.password = bcrypt.hashSync(password, 10);
    user.updatedAt = now();
    return sanitizeUser(user);
  });

const getSubjectsByUser = (userId) => {
  const state = readState();
  const subjects = state.subjects
    .filter((subject) => subject.user === userId)
    .sort(sortByCreatedDesc);

  return clone(subjects);
};

const createSubject = (userId, data) =>
  updateState((state) => {
    const timestamp = now();
    const subject = {
      _id: createId(),
      user: userId,
      name: String(data.name).trim(),
      color: data.color || "#4F46E5",
      creditHours: Number(data.creditHours || 3),
      icon: data.icon || "book",
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.subjects.push(subject);
    return clone(subject);
  });

const updateSubject = (userId, subjectId, updates) =>
  updateState((state) => {
    const subject = state.subjects.find(
      (entry) => entry._id === subjectId && entry.user === userId
    );

    if (!subject) {
      return null;
    }

    Object.assign(subject, updates, { updatedAt: now() });
    return clone(subject);
  });

const deleteSubject = (userId, subjectId) =>
  updateState((state) => {
    const index = state.subjects.findIndex(
      (entry) => entry._id === subjectId && entry.user === userId
    );

    if (index === -1) {
      return false;
    }

    state.subjects.splice(index, 1);

    state.schedules.forEach((schedule) => {
      if (schedule.user === userId && schedule.subject === subjectId) {
        schedule.subject = null;
        schedule.updatedAt = now();
      }
    });

    state.tasks.forEach((task) => {
      if (task.user === userId && task.subject === subjectId) {
        task.subject = null;
        task.updatedAt = now();
      }
    });

    return true;
  });

const getSchedulesByUser = (userId, date) => {
  const state = readState();
  let schedules = state.schedules.filter((schedule) => schedule.user === userId);

  if (date) {
    schedules = schedules.filter(
      (schedule) => String(schedule.date).slice(0, 10) === date
    );
  }

  schedules.sort((a, b) => {
    const dateCompare = new Date(a.date).getTime() - new Date(b.date).getTime();

    if (dateCompare !== 0) {
      return dateCompare;
    }

    return String(a.startTime).localeCompare(String(b.startTime));
  });

  return schedules.map((schedule) => populateSubject(schedule, state, userId));
};

const createSchedule = (userId, data) =>
  updateState((state) => {
    const timestamp = now();
    const schedule = {
      _id: createId(),
      user: userId,
      subject: data.subject || null,
      title: String(data.title).trim(),
      date: data.date,
      startTime: data.startTime,
      endTime: data.endTime,
      notes: data.notes || "",
      completed: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.schedules.push(schedule);
    return populateSubject(schedule, state, userId);
  });

const toggleScheduleComplete = (userId, scheduleId) =>
  updateState((state) => {
    const schedule = state.schedules.find(
      (entry) => entry._id === scheduleId && entry.user === userId
    );

    if (!schedule) {
      return null;
    }

    schedule.completed = !schedule.completed;
    schedule.updatedAt = now();

    return populateSubject(schedule, state, userId);
  });

const deleteSchedule = (userId, scheduleId) =>
  updateState((state) => {
    const index = state.schedules.findIndex(
      (entry) => entry._id === scheduleId && entry.user === userId
    );

    if (index === -1) {
      return false;
    }

    state.schedules.splice(index, 1);
    return true;
  });

const getTasksByUser = (userId, completed) => {
  const state = readState();
  let tasks = state.tasks.filter((task) => task.user === userId);
  const parsedCompleted = parseBool(completed);

  if (parsedCompleted !== undefined) {
    tasks = tasks.filter((task) => task.completed === parsedCompleted);
  }

  tasks.sort((a, b) => {
    const aDue = a.dueDate ? new Date(a.dueDate).getTime() : Number.MAX_SAFE_INTEGER;
    const bDue = b.dueDate ? new Date(b.dueDate).getTime() : Number.MAX_SAFE_INTEGER;

    if (aDue !== bDue) {
      return aDue - bDue;
    }

    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });

  return tasks.map((task) => populateSubject(task, state, userId));
};

const getTaskHistory = (userId) => {
  const state = readState();

  return state.tasks
    .filter((task) => task.user === userId && task.completed)
    .sort((a, b) => {
      const aCompleted = a.completedAt ? new Date(a.completedAt).getTime() : 0;
      const bCompleted = b.completedAt ? new Date(b.completedAt).getTime() : 0;
      return bCompleted - aCompleted;
    })
    .slice(0, 50)
    .map((task) => populateSubject(task, state, userId));
};

const createTask = (userId, data) =>
  updateState((state) => {
    const timestamp = now();
    const task = {
      _id: createId(),
      user: userId,
      subject: data.subject || null,
      title: String(data.title).trim(),
      description: data.description || "",
      category: data.category || "Other",
      dueDate: data.dueDate || null,
      priority: data.priority || "medium",
      completed: false,
      completedAt: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.tasks.push(task);
    return populateSubject(task, state, userId);
  });

const updateTask = (userId, taskId, updates) =>
  updateState((state) => {
    const task = state.tasks.find(
      (entry) => entry._id === taskId && entry.user === userId
    );

    if (!task) {
      return null;
    }

    Object.assign(task, updates, { updatedAt: now() });
    return populateSubject(task, state, userId);
  });

const toggleTaskComplete = (userId, taskId) =>
  updateState((state) => {
    const task = state.tasks.find(
      (entry) => entry._id === taskId && entry.user === userId
    );

    if (!task) {
      return null;
    }

    task.completed = !task.completed;
    task.completedAt = task.completed ? now() : null;
    task.updatedAt = now();

    return populateSubject(task, state, userId);
  });

const deleteTask = (userId, taskId) =>
  updateState((state) => {
    const index = state.tasks.findIndex(
      (entry) => entry._id === taskId && entry.user === userId
    );

    if (index === -1) {
      return false;
    }

    state.tasks.splice(index, 1);
    return true;
  });

module.exports = {
  DB_PATH,
  createUser,
  findUserByEmail,
  findUserById,
  comparePassword,
  updateUser,
  updateUserPassword,
  getSubjectsByUser,
  createSubject,
  updateSubject,
  deleteSubject,
  getSchedulesByUser,
  createSchedule,
  toggleScheduleComplete,
  deleteSchedule,
  getTasksByUser,
  getTaskHistory,
  createTask,
  updateTask,
  toggleTaskComplete,
  deleteTask,
};
