"use client";

import { useEffect, useState } from "react";
import DataTable from "@/components/DataTable";
import EmptyState from "@/components/EmptyState";
import PageHeader from "@/components/PageHeader";
import StatusBadge from "@/components/StatusBadge";
import api from "@/lib/api";
import type { ReminderSummary } from "@/lib/types";

export default function RemindersPage() {
  const [reminders, setReminders] = useState<ReminderSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .get<ReminderSummary[]>("/admin/reminders")
      .then((response) => setReminders(response.data))
      .catch(() => setError("Failed to load reminders."))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <PageHeader title="Reminders" description="Student reminder preferences from the mobile app." />

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}
      {!loading && reminders.length === 0 ? <EmptyState message="No reminders found." /> : null}

      {reminders.length > 0 ? (
        <DataTable
          data={reminders}
          columns={[
            {
              key: "name",
              header: "Student",
              render: (item) => (
                <div>
                  <p className="font-semibold">{item.name || "-"}</p>
                  <p className="text-xs text-muted">{item.email || "-"}</p>
                </div>
              ),
            },
            {
              key: "reminderTime",
              header: "Reminder Time",
              render: (item) => item.notifications?.reminderTime || "15 Mins",
            },
            {
              key: "alertSound",
              header: "Alert Sound",
              render: (item) => item.notifications?.alertSound || "Classic Chime",
            },
            {
              key: "status",
              header: "Account Status",
              render: (item) => (
                <StatusBadge
                  active={item.status !== "blocked"}
                  label={item.status || "active"}
                />
              ),
            },
          ]}
        />
      ) : null}
    </div>
  );
}
