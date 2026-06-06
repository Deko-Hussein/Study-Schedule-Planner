"use client";

import { useEffect, useState } from "react";
import EmptyState from "@/components/EmptyState";
import StatusBadge from "@/components/StatusBadge";
import api from "@/lib/api";
import type { TaskSummary } from "@/lib/types";

export default function TasksPage() {
  const [tasks, setTasks] = useState<TaskSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get<TaskSummary[]>("/admin/tasks")
      .then((response) => setTasks(response.data))
      .catch(() => setError("Failed to load tasks."))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Tasks</h2>
        <p className="text-sm text-muted">All student tasks from the backend.</p>
      </div>

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}
      {!loading && tasks.length === 0 ? <EmptyState message="No tasks found." /> : null}

      {tasks.length > 0 ? (
        <div className="overflow-hidden rounded-2xl border border-line bg-white shadow-soft">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-muted">
                <tr>
                  <th className="px-5 py-4">Task</th>
                  <th className="px-5 py-4">User</th>
                  <th className="px-5 py-4">Subject</th>
                  <th className="px-5 py-4">Priority</th>
                  <th className="px-5 py-4">Status</th>
                  <th className="px-5 py-4">Due Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {tasks.map((task) => (
                  <tr key={task._id}>
                    <td className="px-5 py-4 font-semibold">{task.title || "-"}</td>
                    <td className="px-5 py-4">
                      <p className="font-medium">{task.user?.name || "-"}</p>
                      <p className="text-xs text-muted">{task.user?.email || "-"}</p>
                    </td>
                    <td className="px-5 py-4">{task.subject?.name || "-"}</td>
                    <td className="px-5 py-4 capitalize">{task.priority || "medium"}</td>
                    <td className="px-5 py-4">
                      <StatusBadge
                        active={Boolean(task.completed)}
                        label={task.completed ? "Completed" : "Pending"}
                      />
                    </td>
                    <td className="px-5 py-4">
                      {task.dueDate ? new Date(task.dueDate).toLocaleDateString() : "-"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
    </div>
  );
}
