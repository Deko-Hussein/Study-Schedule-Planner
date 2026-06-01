const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const DATA_FILE = path.join(__dirname, '..', '.local-data.json');

function createEmptyState() {
  return {
    users: [],
    subjects: [],
    tasks: [],
    schedules: [],
  };
}

function ensureNotifications(notifications = {}) {
  return {
    reminderTime: notifications.reminderTime || '15 Mins',
    alertSound: notifications.alertSound || 'Classic Chime',
  };
}

function readState() {
  try {
    if (!fs.existsSync(DATA_FILE)) {
      return createEmptyState();
    }

    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    if (!raw.trim()) {
      return createEmptyState();
    }

    const parsed = JSON.parse(raw);
    return {
      users: Array.isArray(parsed.users) ? parsed.users : [],
      subjects: Array.isArray(parsed.subjects) ? parsed.subjects : [],
      tasks: Array.isArray(parsed.tasks) ? parsed.tasks : [],
      schedules: Array.isArray(parsed.schedules) ? parsed.schedules : [],
    };
  } catch (err) {
    console.error('Failed to read local fallback data:', err.message);
    return createEmptyState();
  }
}

function writeState(state) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(state, null, 2));
}

function withState(mutator) {
  const state = readState();
  const result = mutator(state);
  writeState(state);
  return result;
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function nowIso() {
  return new Date().toISOString();
}

function createId() {
  return crypto.randomUUID();
}

function normalizeEmail(email) {
  return email.trim().toLowerCase();
}

function sanitizeUser(user) {
  if (!user) {
    return null;
  }

  const safeUser = clone(user);
  delete safeUser.password;
  safeUser.notifications = ensureNotifications(safeUser.notifications);
  return safeUser;
}

function subjectSummary(subject) {
  if (!subject) {
    return null;
  }

  return {
    _id: subject._id,
    name: subject.name,
    color: subject.color,
    icon: subject.icon,
  };
}

function sortByCreatedAtDesc(a, b) {
  return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
}

function mapTask(task, subjects) {
  return {
    ...clone(task),
    subject: subjectSummary(subjects.find((subject) => subject._id === task.subject)),
  };
}

function mapSchedule(schedule, subjects) {
  return {
    ...clone(schedule),
    subject: subjectSummary(subjects.find((subject) => subject._id === schedule.subject)),
  };
}

async function findUserByEmail(email, options = {}) {
  const state = readState();
  const user = state.users.find((entry) => entry.email === normalizeEmail(email));
  if (!user) {
    return null;
  }

  return options.includePassword ? clone(user) : sanitizeUser(user);
}

async function findUserById(id, options = {}) {
  const state = readState();
  const user = state.users.find((entry) => entry._id === id);
  if (!user) {
    return null;
  }

  return options.includePassword ? clone(user) : sanitizeUser(user);
}

async function createUser({ name, email, password, major }) {
  const normalizedEmail = normalizeEmail(email);
  const existing = await findUserByEmail(normalizedEmail, { includePassword: true });
  if (existing) {
    return null;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const timestamp = nowIso();

  return withState((state) => {
    const user = {
      _id: createId(),
      name: name.trim(),
      email: normalizedEmail,
      password: passwordHash,
      major: major || '',
      avatar: '',
      subscription: 'free',
      notifications: ensureNotifications(),
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.users.push(user);
    return sanitizeUser(user);
  });
}

async function comparePassword(userId, plainPassword) {
  const user = await findUserById(userId, { includePassword: true });
  if (!user) {
    return false;
  }

  return bcrypt.compare(plainPassword, user.password);
}

async function updateUser(id, updates) {
  return withState((state) => {
    const user = state.users.find((entry) => entry._id === id);
    if (!user) {
      return null;
    }

    if (updates.name !== undefined) {
      user.name = updates.name;
    }
    if (updates.major !== undefined) {
      user.major = updates.major;
    }
    if (updates.avatar !== undefined) {
      user.avatar = updates.avatar;
    }
    if (updates.notifications !== undefined) {
      user.notifications = ensureNotifications(updates.notifications);
    }

    user.updatedAt = nowIso();
    return sanitizeUser(user);
  });
}

async function updateUserPassword(id, newPassword) {
  const passwordHash = await bcrypt.hash(newPassword, 10);

  return withState((state) => {
    const user = state.users.find((entry) => entry._id === id);
    if (!user) {
      return null;
    }

    user.password = passwordHash;
    user.updatedAt = nowIso();
    return sanitizeUser(user);
  });
}

async function listSubjects(userId) {
  const state = readState();
  return state.subjects
    .filter((subject) => subject.user === userId)
    .sort(sortByCreatedAtDesc)
    .map((subject) => clone(subject));
}

async function createSubject(userId, data) {
  const timestamp = nowIso();

  return withState((state) => {
    const subject = {
      _id: createId(),
      user: userId,
      name: data.name,
      color: data.color || '#4F46E5',
      creditHours: data.creditHours || 3,
      icon: data.icon || 'book',
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.subjects.push(subject);
    return clone(subject);
  });
}

async function updateSubject(userId, subjectId, updates) {
  return withState((state) => {
    const subject = state.subjects.find((entry) => entry._id === subjectId && entry.user === userId);
    if (!subject) {
      return null;
    }

    Object.assign(subject, updates, { updatedAt: nowIso() });
    return clone(subject);
  });
}

async function deleteSubject(userId, subjectId) {
  return withState((state) => {
    const index = state.subjects.findIndex((entry) => entry._id === subjectId && entry.user === userId);
    if (index === -1) {
      return null;
    }

    const [subject] = state.subjects.splice(index, 1);
    return clone(subject);
  });
}

function sortTasks(tasks) {
  return tasks.sort((left, right) => {
    const leftDue = left.dueDate ? new Date(left.dueDate).getTime() : Number.MAX_SAFE_INTEGER;
    const rightDue = right.dueDate ? new Date(right.dueDate).getTime() : Number.MAX_SAFE_INTEGER;
    if (leftDue !== rightDue) {
      return leftDue - rightDue;
    }

    return new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime();
  });
}

async function listTasks(userId, completed) {
  const state = readState();
  let tasks = state.tasks.filter((task) => task.user === userId);
  if (completed !== undefined) {
    tasks = tasks.filter((task) => task.completed === completed);
  }

  return sortTasks(tasks).map((task) => mapTask(task, state.subjects));
}

async function listTaskHistory(userId) {
  const state = readState();
  return state.tasks
    .filter((task) => task.user === userId && task.completed)
    .sort((left, right) => new Date(right.completedAt || 0).getTime() - new Date(left.completedAt || 0).getTime())
    .slice(0, 50)
    .map((task) => mapTask(task, state.subjects));
}

async function createTask(userId, data) {
  const timestamp = nowIso();

  return withState((state) => {
    const task = {
      _id: createId(),
      user: userId,
      subject: data.subject || null,
      title: data.title,
      description: data.description || '',
      category: data.category || 'Other',
      dueDate: data.dueDate || null,
      priority: data.priority || 'medium',
      completed: false,
      completedAt: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.tasks.push(task);
    return mapTask(task, state.subjects);
  });
}

async function updateTask(userId, taskId, updates) {
  return withState((state) => {
    const task = state.tasks.find((entry) => entry._id === taskId && entry.user === userId);
    if (!task) {
      return null;
    }

    Object.assign(task, updates, { updatedAt: nowIso() });
    return mapTask(task, state.subjects);
  });
}

async function toggleTaskComplete(userId, taskId) {
  return withState((state) => {
    const task = state.tasks.find((entry) => entry._id === taskId && entry.user === userId);
    if (!task) {
      return null;
    }

    task.completed = !task.completed;
    task.completedAt = task.completed ? nowIso() : null;
    task.updatedAt = nowIso();
    return mapTask(task, state.subjects);
  });
}

async function deleteTask(userId, taskId) {
  return withState((state) => {
    const index = state.tasks.findIndex((entry) => entry._id === taskId && entry.user === userId);
    if (index === -1) {
      return null;
    }

    const [task] = state.tasks.splice(index, 1);
    return mapTask(task, state.subjects);
  });
}

async function listSchedules(userId, date) {
  const state = readState();
  let schedules = state.schedules.filter((schedule) => schedule.user === userId);

  if (date) {
    const start = new Date(date);
    const end = new Date(date);
    end.setDate(end.getDate() + 1);
    schedules = schedules.filter((schedule) => {
      const scheduleDate = new Date(schedule.date);
      return scheduleDate >= start && scheduleDate < end;
    });
  }

  return schedules
    .sort((left, right) => {
      const byDate = new Date(left.date).getTime() - new Date(right.date).getTime();
      if (byDate !== 0) {
        return byDate;
      }

      return left.startTime.localeCompare(right.startTime);
    })
    .map((schedule) => mapSchedule(schedule, state.subjects));
}

async function createSchedule(userId, data) {
  const timestamp = nowIso();

  return withState((state) => {
    const schedule = {
      _id: createId(),
      user: userId,
      subject: data.subject,
      title: data.title,
      date: data.date,
      startTime: data.startTime,
      endTime: data.endTime,
      notes: data.notes || '',
      completed: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    state.schedules.push(schedule);
    return mapSchedule(schedule, state.subjects);
  });
}

async function updateSchedule(userId, scheduleId, updates) {
  return withState((state) => {
    const schedule = state.schedules.find((entry) => entry._id === scheduleId && entry.user === userId);
    if (!schedule) {
      return null;
    }

    Object.assign(schedule, updates, { updatedAt: nowIso() });
    return mapSchedule(schedule, state.subjects);
  });
}

async function toggleScheduleComplete(userId, scheduleId) {
  return withState((state) => {
    const schedule = state.schedules.find((entry) => entry._id === scheduleId && entry.user === userId);
    if (!schedule) {
      return null;
    }

    schedule.completed = !schedule.completed;
    schedule.updatedAt = nowIso();
    return mapSchedule(schedule, state.subjects);
  });
}

async function deleteSchedule(userId, scheduleId) {
  return withState((state) => {
    const index = state.schedules.findIndex((entry) => entry._id === scheduleId && entry.user === userId);
    if (index === -1) {
      return null;
    }

    const [schedule] = state.schedules.splice(index, 1);
    return mapSchedule(schedule, state.subjects);
  });
}

async function getReminders(userId) {
  const user = await findUserById(userId);
  return user ? ensureNotifications(user.notifications) : null;
}

async function updateReminders(userId, updates) {
  return withState((state) => {
    const user = state.users.find((entry) => entry._id === userId);
    if (!user) {
      return null;
    }

    user.notifications = ensureNotifications({
      ...user.notifications,
      ...updates,
    });
    user.updatedAt = nowIso();
    return clone(user.notifications);
  });
}

module.exports = {
  comparePassword,
  createSchedule,
  createSubject,
  createTask,
  createUser,
  deleteSchedule,
  deleteSubject,
  deleteTask,
  findUserByEmail,
  findUserById,
  getReminders,
  listSchedules,
  listSubjects,
  listTaskHistory,
  listTasks,
  updateReminders,
  updateSchedule,
  updateSubject,
  updateTask,
  updateUser,
  updateUserPassword,
  toggleScheduleComplete,
  toggleTaskComplete,
};
