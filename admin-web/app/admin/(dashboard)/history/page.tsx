"use client";

import { useEffect, useState } from "react";
import DataTable from "@/components/DataTable";
import EmptyState from "@/components/EmptyState";
import PageHeader from "@/components/PageHeader";
import StatusBadge from "@/components/StatusBadge";
import api from "@/lib/api";
import type { TaskSummary } from "@/lib/types";

export default function HistoryPage() {
  const [history, setHistory] = useState<TaskSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get<TaskSummary[]>("/admin/history")
      .then((response) => setHistory(response.data))
      .catch(() => setError("Failed to load history."))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <PageHeader title="History" description="Completed student tasks from the mobile app." />

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}
      {!loading && history.length === 0 ? <EmptyState message="No history found." /> : null}

      {history.length > 0 ? (
        <DataTable
          data={history}
          columns={[
            {
              key: "task",
              header: "Task",
              render: (task) => <span className="font-semibold">{task.title || "-"}</span>,
            },
            {
              key: "user",
              header: "User",
              render: (task) => (
                <div>
                  <p className="font-medium">{task.user?.name || "-"}</p>
                  <p className="text-xs text-muted">{task.user?.email || "-"}</p>
                </div>
              ),
            },
            {
              key: "subject",
              header: "Subject",
              render: (task) => task.subject?.name || "-",
            },
            {
              key: "priority",
              header: "Priority",
              render: (task) => <span className="capitalize">{task.priority || "medium"}</span>,
            },
            {
              key: "status",
              header: "Status",
              render: () => <StatusBadge active label="Completed" />,
            },
            {
              key: "date",
              header: "Completed",
              render: (task) =>
                task.dueDate ? new Date(task.dueDate).toLocaleDateString() : "-",
            },
          ]}
        />
      ) : null}
    </div>
  );
}
