"use client";

import { useEffect, useMemo, useState } from "react";
import { Bell, CheckCircle2, Clock, History, ListTodo, Percent } from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import ChartCard from "@/components/ChartCard";
import EmptyState from "@/components/EmptyState";
import PageHeader from "@/components/PageHeader";
import StatCard from "@/components/StatCard";
import api from "@/lib/api";
import type { DashboardStats, ReminderSummary, TaskSummary, UserSummary } from "@/lib/types";

export default function AnalyticsPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [tasks, setTasks] = useState<TaskSummary[]>([]);
  const [history, setHistory] = useState<TaskSummary[]>([]);
  const [reminders, setReminders] = useState<ReminderSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    Promise.all([
      api.get<DashboardStats>("/admin/dashboard"),
      api.get<UserSummary[]>("/admin/users"),
      api.get<TaskSummary[]>("/admin/tasks"),
      api.get<TaskSummary[]>("/admin/history"),
      api.get<ReminderSummary[]>("/admin/reminders"),
    ])
      .then(([dashboardRes, usersRes, tasksRes, historyRes, remindersRes]) => {
        setStats(dashboardRes.data);
        setUsers(usersRes.data);
        setTasks(tasksRes.data);
        setHistory(historyRes.data);
        setReminders(remindersRes.data);
      })
      .catch(() => setError("Failed to load analytics data."))
      .finally(() => setLoading(false));
  }, []);

  const analytics = useMemo(() => {
    const byMonth = new Map<string, number>();
    users.forEach((user) => {
      if (!user.createdAt) return;
      const date = new Date(user.createdAt);
      const key = date.toLocaleString("default", { month: "short", year: "2-digit" });
      byMonth.set(key, (byMonth.get(key) || 0) + 1);
    });

    const priorityCounts = new Map<string, number>();
    tasks.forEach((task) => {
      const priority = task.priority || "medium";
      priorityCounts.set(priority, (priorityCounts.get(priority) || 0) + 1);
    });

    const reminderCounts = new Map<string, number>();
    reminders.forEach((reminder) => {
      const time = reminder.notifications?.reminderTime || "15 Mins";
      reminderCounts.set(time, (reminderCounts.get(time) || 0) + 1);
    });

    const totalTasks = stats?.totalTasks || tasks.length;
    const completedTasks = stats?.completedTasks || history.length;
    const pendingTasks = stats?.pendingTasks || tasks.filter((task) => !task.completed).length;
    const completionPercentage =
      totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

    return {
      userGrowth: Array.from(byMonth.entries()).map(([month, registrations]) => ({
        month,
        registrations,
      })),
      taskPriorities: Array.from(priorityCounts.entries()).map(([priority, count]) => ({
        priority,
        count,
      })),
      reminderUsage: Array.from(reminderCounts.entries()).map(([time, count]) => ({
        time,
        count,
      })),
      totalTasks,
      completedTasks,
      pendingTasks,
      completionPercentage,
      totalHistory: history.length,
      totalReminders: reminders.length,
    };
  }, [history, reminders, stats, tasks, users]);

  const hasData = users.length > 0 || tasks.length > 0 || history.length > 0 || reminders.length > 0;

  const pieData = [
    { name: "Completed", value: analytics.completedTasks, color: "#10B981" },
    { name: "Pending", value: analytics.pendingTasks, color: "#F59E0B" },
  ];

  return (
    <div className="space-y-8">
      <PageHeader
        title="Analytics"
        description="Mobile app activity for users, tasks, history, and reminders."
      />

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}
      {!loading && !hasData ? <EmptyState message="No analytics data available" /> : null}

      {hasData ? (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Total Tasks" value={analytics.totalTasks} icon={ListTodo} />
            <StatCard label="Completed Tasks" value={analytics.completedTasks} icon={CheckCircle2} />
            <StatCard label="Pending Tasks" value={analytics.pendingTasks} icon={Clock} />
            <StatCard label="Completion" value={`${analytics.completionPercentage}%`} icon={Percent} />
          </section>

          <section className="grid gap-6 xl:grid-cols-2">
            <ChartCard title="User Growth">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={analytics.userGrowth}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Line type="monotone" dataKey="registrations" stroke="#4F46E5" strokeWidth={3} />
                </LineChart>
              </ResponsiveContainer>
            </ChartCard>

            <ChartCard title="Task Completion">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={pieData} dataKey="value" nameKey="name" outerRadius={95} label>
                    {pieData.map((entry) => (
                      <Cell key={entry.name} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </ChartCard>
          </section>

          <section className="grid gap-6 xl:grid-cols-2">
            <ChartCard title="Tasks By Priority">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={analytics.taskPriorities}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="priority" />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#4F46E5" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>

            <ChartCard title="Reminder Preferences">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={analytics.reminderUsage}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#10B981" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </section>

          <section className="grid gap-4 sm:grid-cols-2">
            <StatCard label="History Items" value={analytics.totalHistory} icon={History} />
            <StatCard label="Reminder Profiles" value={analytics.totalReminders} icon={Bell} />
          </section>
        </>
      ) : null}
    </div>
  );
}
