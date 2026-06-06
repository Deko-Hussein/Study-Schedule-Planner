"use client";

import { useEffect, useState } from "react";
import { Bell, CheckCircle2, Clock, History, ListTodo, Users } from "lucide-react";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import api from "@/lib/api";
import type { DashboardStats } from "@/lib/types";

const initialStats: DashboardStats = {
  totalUsers: 0,
  totalTasks: 0,
  completedTasks: 0,
  pendingTasks: 0,
  totalHistory: 0,
  totalReminders: 0,
};

const cards = [
  { key: "totalUsers", label: "Total Users", icon: Users },
  { key: "totalTasks", label: "Total Tasks", icon: ListTodo },
  { key: "completedTasks", label: "Completed Tasks", icon: CheckCircle2 },
  { key: "pendingTasks", label: "Pending Tasks", icon: Clock },
  { key: "totalHistory", label: "History Items", icon: History },
  { key: "totalReminders", label: "Reminder Profiles", icon: Bell },
] as const;

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>(initialStats);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get<DashboardStats>("/admin/dashboard")
      .then((response) => setStats(response.data))
      .catch(() => setError("Failed to load dashboard data."))
      .finally(() => setLoading(false));
  }, []);

  const chartData = [
    { name: "Completed", value: stats.completedTasks, color: "#10B981" },
    { name: "Pending", value: stats.pendingTasks, color: "#F59E0B" },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold">Dashboard</h2>
        <p className="text-sm text-muted">Overview of students, tasks, history, and reminders.</p>
      </div>

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.key} className="rounded-2xl border border-line bg-white p-5 shadow-soft">
              <div className="flex items-center justify-between">
                <p className="text-sm font-semibold text-muted">{card.label}</p>
                <span className="rounded-xl bg-indigo-50 p-2 text-brand">
                  <Icon size={20} />
                </span>
              </div>
              <p className="mt-4 text-3xl font-bold">
                {loading ? "..." : stats[card.key]}
              </p>
            </div>
          );
        })}
      </section>

      <section className="rounded-2xl border border-line bg-white p-6 shadow-soft">
        <h3 className="text-lg font-bold">Completed vs Pending Tasks</h3>
        <div className="mt-4 h-72">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie data={chartData} dataKey="value" nameKey="name" outerRadius={95} label>
                {chartData.map((entry) => (
                  <Cell key={entry.name} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </section>
    </div>
  );
}
