import { Search } from "lucide-react";

export default function SearchBar({
  value,
  onChange,
  placeholder = "Search",
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-line bg-white px-4 py-3">
      <Search size={18} className="text-muted" />
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full outline-none"
        placeholder={placeholder}
      />
    </div>
  );
}
