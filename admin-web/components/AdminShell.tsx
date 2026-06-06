"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Bell,
  CheckSquare,
  FileText,
  History,
  LayoutDashboard,
  LogOut,
  Menu,
  Settings,
  TrendingUp,
  Users,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";
import api, { API_TOKEN_KEY } from "@/lib/api";

const navItems = [
  { href: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/admin/users", label: "Users", icon: Users },
  { href: "/admin/tasks", label: "Tasks", icon: CheckSquare },
  { href: "/admin/history", label: "History", icon: History },
  { href: "/admin/reminders", label: "Reminders", icon: Bell },
  { href: "/admin/analytics", label: "Analytics", icon: TrendingUp },
  { href: "/admin/reports", label: "Reports", icon: FileText },
  { href: "/admin/settings", label: "Settings", icon: Settings },
];

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const token = window.localStorage.getItem(API_TOKEN_KEY);
    if (!token) {
      router.replace("/admin/login");
      return;
    }

    api.get("/admin/dashboard").catch(() => {
      window.localStorage.removeItem(API_TOKEN_KEY);
      document.cookie = `${API_TOKEN_KEY}=; path=/; max-age=0`;
      router.replace("/admin/login");
    });
  }, [router]);

  const logout = () => {
    window.localStorage.removeItem(API_TOKEN_KEY);
    document.cookie = `${API_TOKEN_KEY}=; path=/; max-age=0`;
    router.replace("/admin/login");
  };

  return (
    <div className="min-h-screen bg-white text-ink">
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-72 border-r border-line bg-white px-5 py-6 transition-transform lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="mb-8 flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold text-brand">Admin</p>
            <h1 className="text-xl font-bold">Study Planner</h1>
          </div>
          <button
            className="rounded-lg p-2 text-muted hover:bg-gray-100 lg:hidden"
            onClick={() => setOpen(false)}
            aria-label="Close menu"
          >
            <X size={20} />
          </button>
        </div>

        <nav className="space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className={`flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition ${
                  active
                    ? "bg-brand text-white shadow-soft"
                    : "text-muted hover:bg-gray-100 hover:text-ink"
                }`}
              >
                <Icon size={18} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <button
          onClick={logout}
          className="absolute bottom-6 left-5 right-5 flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold text-red-600 hover:bg-red-50"
        >
          <LogOut size={18} />
          Logout
        </button>
      </aside>

      {open ? (
        <button
          className="fixed inset-0 z-30 bg-black/20 lg:hidden"
          onClick={() => setOpen(false)}
          aria-label="Close overlay"
        />
      ) : null}

      <div className="lg:pl-72">
        <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-line bg-white/95 px-4 backdrop-blur lg:px-8">
          <button
            className="rounded-lg p-2 text-muted hover:bg-gray-100 lg:hidden"
            onClick={() => setOpen(true)}
            aria-label="Open menu"
          >
            <Menu size={22} />
          </button>
          <div>
            <p className="text-sm font-medium text-muted">Admin Dashboard</p>
            <p className="text-xs text-muted">Real-time data from backend API</p>
          </div>
        </header>
        <main className="p-4 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
