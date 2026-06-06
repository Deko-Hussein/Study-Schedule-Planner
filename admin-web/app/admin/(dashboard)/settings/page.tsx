"use client";

import { FormEvent, useEffect, useState } from "react";
import PageHeader from "@/components/PageHeader";
import api from "@/lib/api";
import type { UserSummary } from "@/lib/types";

export default function SettingsPage() {
  const [admin, setAdmin] = useState<UserSummary | null>(null);
  const [name, setName] = useState("");
  const [major, setMajor] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<{ user: UserSummary }>("/users/me")
      .then((response) => {
        setAdmin(response.data.user);
        setName(response.data.user.name || "");
        setMajor(response.data.user.major || "");
      })
      .catch(() => setError("Failed to load admin profile."))
      .finally(() => setLoading(false));
  }, []);

  const updateProfile = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setMessage("");
    setError("");

    try {
      const response = await api.put<{ user: UserSummary }>("/users/me", { name, major });
      setAdmin(response.data.user);
      setMessage("Profile updated successfully.");
    } catch {
      setError("Failed to update profile.");
    }
  };

  const changePassword = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setMessage("");
    setError("");

    try {
      await api.put("/users/me/password", { currentPassword, newPassword });
      setCurrentPassword("");
      setNewPassword("");
      setMessage("Password updated successfully.");
    } catch {
      setError("Failed to update password.");
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Settings" description="Manage your admin profile and password." />

      {message ? <p className="rounded-xl bg-emerald-50 p-4 text-sm text-emerald-700">{message}</p> : null}
      {error ? <p className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p> : null}

      <section className="grid gap-6 xl:grid-cols-[1fr_1fr]">
        <div className="rounded-2xl border border-line bg-white p-6 shadow-soft">
          <h3 className="text-lg font-bold">Admin Profile</h3>
          <div className="mt-5 space-y-3 text-sm">
            <p>
              <span className="font-semibold">Admin Name:</span>{" "}
              {loading ? "Loading..." : admin?.name || "-"}
            </p>
            <p>
              <span className="font-semibold">Admin Email:</span>{" "}
              {loading ? "Loading..." : admin?.email || "-"}
            </p>
            <p>
              <span className="font-semibold">Role:</span>{" "}
              {loading ? "Loading..." : admin?.role || "-"}
            </p>
          </div>
        </div>

        <form onSubmit={updateProfile} className="rounded-2xl border border-line bg-white p-6 shadow-soft">
          <h3 className="text-lg font-bold">Update Profile</h3>
          <div className="mt-5 space-y-4">
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Name</span>
              <input
                value={name}
                onChange={(event) => setName(event.target.value)}
                className="w-full rounded-2xl border border-line px-4 py-3 outline-none focus:border-brand"
              />
            </label>
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Major</span>
              <input
                value={major}
                onChange={(event) => setMajor(event.target.value)}
                className="w-full rounded-2xl border border-line px-4 py-3 outline-none focus:border-brand"
              />
            </label>
            <button className="rounded-xl bg-brand px-5 py-3 text-sm font-semibold text-white">
              Update profile
            </button>
          </div>
        </form>
      </section>

      <form onSubmit={changePassword} className="rounded-2xl border border-line bg-white p-6 shadow-soft">
        <h3 className="text-lg font-bold">Change Password</h3>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <label className="block">
            <span className="mb-2 block text-sm font-semibold">Current password</span>
            <input
              value={currentPassword}
              onChange={(event) => setCurrentPassword(event.target.value)}
              type="password"
              className="w-full rounded-2xl border border-line px-4 py-3 outline-none focus:border-brand"
              required
            />
          </label>
          <label className="block">
            <span className="mb-2 block text-sm font-semibold">New password</span>
            <input
              value={newPassword}
              onChange={(event) => setNewPassword(event.target.value)}
              type="password"
              className="w-full rounded-2xl border border-line px-4 py-3 outline-none focus:border-brand"
              required
              minLength={6}
            />
          </label>
        </div>
        <button className="mt-5 rounded-xl bg-brand px-5 py-3 text-sm font-semibold text-white">
          Change password
        </button>
      </form>
    </div>
  );
}
