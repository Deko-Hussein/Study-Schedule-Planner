export type DashboardStats = {
  totalUsers: number;
  totalTasks: number;
  completedTasks: number;
  pendingTasks: number;
  totalHistory?: number;
  totalReminders?: number;
};

export type UserSummary = {
  _id: string;
  name?: string;
  email?: string;
  major?: string;
  role?: "student" | "admin";
  status?: "active" | "blocked";
  createdAt?: string;
};

export type SubjectSummary = {
  _id?: string;
  name?: string;
  color?: string;
  creditHours?: number;
  user?: UserSummary;
  createdAt?: string;
};

export type TaskSummary = {
  _id: string;
  title?: string;
  user?: UserSummary;
  subject?: SubjectSummary | null;
  priority?: "low" | "medium" | "high";
  completed?: boolean;
  dueDate?: string | null;
  createdAt?: string;
};

export type ScheduleSummary = {
  _id: string;
  title?: string;
  user?: UserSummary;
  subject?: SubjectSummary | null;
  date?: string;
  startTime?: string;
  endTime?: string;
  completed?: boolean;
  createdAt?: string;
};

export type ReminderSummary = {
  _id: string;
  name?: string;
  email?: string;
  status?: "active" | "blocked";
  notifications?: {
    reminderTime?: string;
    alertSound?: string;
  };
};
