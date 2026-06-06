"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { Lock, Mail } from "lucide-react";
import api, { API_TOKEN_KEY } from "@/lib/api";

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setError("");

    try {
      const loginResponse = await api.post("/admin-auth/login", { email, password });
      const token = loginResponse.data.token as string;
      window.localStorage.setItem(API_TOKEN_KEY, token);
      document.cookie = `${API_TOKEN_KEY}=${token}; path=/; max-age=2592000; sameSite=lax`;

      await api.get("/admin/dashboard");
      router.replace("/admin/dashboard");
    } catch (err) {
      window.localStorage.removeItem(API_TOKEN_KEY);
      document.cookie = `${API_TOKEN_KEY}=; path=/; max-age=0`;
      setError("Login failed. Use an admin account and check your password.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-white px-4">
      <section className="w-full max-w-md rounded-3xl border border-line bg-white p-8 shadow-soft">
        <div className="mb-8">
          <p className="text-sm font-semibold text-brand">Study Planner Admin</p>
          <h1 className="mt-2 text-3xl font-bold text-ink">Welcome back</h1>
          <p className="mt-2 text-sm text-muted">
            Sign in with an admin account to manage the platform.
          </p>
        </div>

        <form onSubmit={submit} className="space-y-5">
          <label className="block">
            <span className="mb-2 block text-sm font-semibold text-ink">Email</span>
            <div className="flex items-center gap-3 rounded-2xl border border-line px-4 py-3 focus-within:border-brand">
              <Mail size={18} className="text-muted" />
              <input
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="w-full outline-none"
                type="email"
                placeholder="admin@example.com"
                required
              />
            </div>
          </label>

          <label className="block">
            <span className="mb-2 block text-sm font-semibold text-ink">Password</span>
            <div className="flex items-center gap-3 rounded-2xl border border-line px-4 py-3 focus-within:border-brand">
              <Lock size={18} className="text-muted" />
              <input
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="w-full outline-none"
                type="password"
                placeholder="Enter password"
                required
              />
            </div>
          </label>

          {error ? (
            <p className="rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
              {error}
            </p>
          ) : null}

          <button
            disabled={loading}
            className="w-full rounded-2xl bg-brand px-4 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-300"
          >
            {loading ? "Signing in..." : "Login"}
          </button>
        </form>
      </section>
    </main>
  );
}
