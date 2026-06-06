export default function PageHeader({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <div>
      <h2 className="text-2xl font-bold">{title}</h2>
      {description ? <p className="text-sm text-muted">{description}</p> : null}
    </div>
  );
}
