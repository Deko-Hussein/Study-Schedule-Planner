"use client";

import { useEffect, useMemo, useState } from "react";
import { Download } from "lucide-react";
import EmptyState from "@/components/EmptyState";
import PageHeader from "@/components/PageHeader";
import SearchBar from "@/components/SearchBar";
import api from "@/lib/api";
import { exportCsv } from "@/lib/exportCsv";
import type { ReminderSummary, TaskSummary, UserSummary } from "@/lib/types";

type ReportKind = "users" | "tasks" | "history" | "reminders";

const reports: { key: ReportKind; title: string; description: string }[] = [
  { key: "users", title: "User Report", description: "Export student account data." },
  { key: "tasks", title: "Task Report", description: "Export all task records." },
  { key: "history", title: "History Report", description: "Export completed task history." },
  { key: "reminders", title: "Reminder Report", description: "Export reminder preferences." },
];

function contains(value: unknown, query: string) {
  return String(value || "").toLowerCase().includes(query.toLowerCase());
}

export default function ReportsPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [tasks, setTasks] = useState<TaskSummary[]>([]);
  const [history, setHistory] = useState<TaskSummary[]>([]);
  const [reminders, setReminders] = useState<ReminderSummary[]>([]);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    Promise.all([
      api.get<UserSummary[]>("/admin/users"),
      api.get<TaskSummary[]>("/admin/tasks"),
      api.get<TaskSummary[]>("/admin/history"),
      api.get<ReminderSummary[]>("/admin/reminders"),
    ])
      .then(([usersRes, tasksRes, historyRes, remindersRes]) => {
        setUsers(usersRes.data);
        setTasks(tasksRes.data);
        setHistory(historyRes.data);
        setReminders(remindersRes.data);
      })
      .catch(() => setError("Failed to load reports data."))
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    const filteredUsers = users.filter((user) => {
      const matchesSearch =
        contains(user.name, search) ||
        contains(user.email, search) ||
        contains(user.major, search) ||
        contains(user.role, search) ||
        contains(user.status, search);
      const matchesStatus = statusFilter === "all" || user.status === statusFilter;
      return matchesSearch && matchesStatus;
    });

    const filterTask = (task: TaskSummary) => {
      const matchesSearch =
        contains(task.title, search) ||
        contains(task.user?.name, search) ||
        contains(task.user?.email, search) ||
        contains(task.subject?.name, search) ||
        contains(task.priority, search);
      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "completed" && task.completed) ||
        (statusFilter === "pending" && !task.completed);
      return matchesSearch && matchesStatus;
    };

    const filteredReminders = reminders.filter((reminder) => {
      const matchesSearch =
        contains(reminder.name, search) ||
        contains(reminder.email, search) ||
        contains(reminder.status, search) ||
        contains(reminder.notifications?.reminderTime, search) ||
        contains(reminder.notifications?.alertSound, search);
      const matchesStatus = statusFilter === "all" || reminder.status === statusFilter;
      return matchesSearch && matchesStatus;
    });

    return {
      users: filteredUsers,
      tasks: tasks.filter(filterTask),
      history: history.filter(filterTask),
      reminders: filteredReminders,
    };
  }, [history, reminders, search, statusFilter, tasks, users]);

  const exportReport = (kind: ReportKind) => {
    if (kind === "users") {
      exportCsv("users-report.csv", filtered.users.map((user) => ({
        name: user.name,
        email: user.email,
        major: user.major,
        role: user.role,
        status: user.status,
      })));
    }

    if (kind === "tasks" || kind === "history") {
      const rows = filtered[kind].map((task) => ({
        title: task.title,
        userName: task.user?.name,
        userEmail: task.user?.email,
        subject: task.subject?.name,
        priority: task.priority,
        completed: Boolean(task.completed),
        dueDate: task.dueDate ? new Date(task.dueDate).toLocaleDateString() : "",
      }));
      exportCsv(`${kind}-report.csv`, rows);
    }

    if (kind === "reminders") {
      exportCsv("reminders-report.csv", filtered.reminders.map((reminder) => ({
        name: reminder.name,
        email: reminder.email,
        reminderTime: reminder.notifications?.reminderTime,
        alertSound: reminder.notifications?.alertSound,
        status: reminder.status,
      })));
    }
  };

  const counts = {
    users: filtered.users.length,
    tasks: filtered.tasks.length,
    history: filtered.history.length,
    reminders: filtered.reminders.length,
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Reports" description="Filter mobile app data and export CSV files." />

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}

      <section className="grid gap-4 lg:grid-cols-[1fr_220px]">
        <SearchBar value={search} onChange={setSearch} placeholder="Search before export" />
        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value)}
          className="rounded-2xl border border-line bg-white px-4 py-3 outline-none"
        >
          <option value="all">All statuses</option>
          <option value="active">Active users</option>
          <option value="blocked">Blocked users</option>
          <option value="completed">Completed tasks</option>
          <option value="pending">Pending tasks</option>
        </select>
      </section>

      {!loading && users.length === 0 && tasks.length === 0 && history.length === 0 && reminders.length === 0 ? (
        <EmptyState message="No report data available." />
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {reports.map((report) => (
          <article key={report.key} className="rounded-2xl border border-line bg-white p-5 shadow-soft">
            <h3 className="text-lg font-bold">{report.title}</h3>
            <p className="mt-1 text-sm text-muted">{report.description}</p>
            <p className="mt-5 text-3xl font-bold">{loading ? "..." : counts[report.key]}</p>
            <button
              onClick={() => exportReport(report.key)}
              disabled={counts[report.key] === 0}
              className="mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-4 py-3 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:bg-indigo-300"
            >
              <Download size={16} />
              Export CSV
            </button>
          </article>
        ))}
      </section>
    </div>
  );
}
