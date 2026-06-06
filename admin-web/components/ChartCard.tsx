export default function ChartCard({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-line bg-white p-6 shadow-soft">
      <h3 className="text-lg font-bold">{title}</h3>
      <div className="mt-4 h-72">{children}</div>
    </section>
  );
}
