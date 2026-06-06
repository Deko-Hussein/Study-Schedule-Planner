import type { LucideIcon } from "lucide-react";

export default function StatCard({
  label,
  value,
  icon: Icon,
}: {
  label: string;
  value: string | number;
  icon: LucideIcon;
}) {
  return (
    <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex items-center justify-between">
        <p className="text-sm font-semibold text-muted">{label}</p>
        <span className="rounded-xl bg-indigo-50 p-2 text-brand">
          <Icon size={20} />
        </span>
      </div>
      <p className="mt-4 text-3xl font-bold">{value}</p>
    </div>
  );
}
