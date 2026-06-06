export default function EmptyState({ message }: { message: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-line bg-white p-8 text-center text-sm font-medium text-muted">
      {message}
    </div>
  );
}
