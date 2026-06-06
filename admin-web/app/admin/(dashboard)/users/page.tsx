"use client";

import { useEffect, useState } from "react";
import { Trash2 } from "lucide-react";
import EmptyState from "@/components/EmptyState";
import StatusBadge from "@/components/StatusBadge";
import api from "@/lib/api";
import type { UserSummary } from "@/lib/types";

export default function UsersPage() {
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadUsers = async () => {
    setLoading(true);
    try {
      const response = await api.get<UserSummary[]>("/admin/users");
      setUsers(response.data);
      setError("");
    } catch {
      setError("Failed to load users.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const updateStatus = async (id: string, status: "active" | "blocked") => {
    await api.patch(`/admin/users/${id}/status`, { status });
    await loadUsers();
  };

  const deleteUser = async (id: string) => {
    await api.delete(`/admin/users/${id}`);
    await loadUsers();
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Users</h2>
        <p className="text-sm text-muted">Manage student accounts.</p>
      </div>

      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}

      {!loading && users.length === 0 ? <EmptyState message="No users found." /> : null}

      {users.length > 0 ? (
        <div className="overflow-hidden rounded-2xl border border-line bg-white shadow-soft">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-muted">
                <tr>
                  <th className="px-5 py-4">Name</th>
                  <th className="px-5 py-4">Email</th>
                  <th className="px-5 py-4">Major</th>
                  <th className="px-5 py-4">Role</th>
                  <th className="px-5 py-4">Status</th>
                  <th className="px-5 py-4">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {users.map((user) => (
                  <tr key={user._id}>
                    <td className="px-5 py-4 font-semibold">{user.name || "-"}</td>
                    <td className="px-5 py-4 text-muted">{user.email || "-"}</td>
                    <td className="px-5 py-4">{user.major || "-"}</td>
                    <td className="px-5 py-4">{user.role || "student"}</td>
                    <td className="px-5 py-4">
                      <StatusBadge
                        active={user.status !== "blocked"}
                        label={user.status || "active"}
                      />
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex flex-wrap gap-2">
                        {user.status === "blocked" ? (
                          <button
                            onClick={() => updateStatus(user._id, "active")}
                            className="rounded-lg bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-700"
                          >
                            Activate
                          </button>
                        ) : (
                          <button
                            onClick={() => updateStatus(user._id, "blocked")}
                            className="rounded-lg bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-700"
                          >
                            Block
                          </button>
                        )}
                        <button
                          onClick={() => deleteUser(user._id)}
                          className="rounded-lg bg-red-50 px-3 py-2 text-xs font-semibold text-red-700"
                          aria-label="Delete user"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
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
