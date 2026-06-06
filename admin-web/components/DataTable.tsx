export type DataTableColumn<T> = {
  key: string;
  header: string;
  render: (item: T) => React.ReactNode;
};

export default function DataTable<T extends { _id?: string }>({
  columns,
  data,
}: {
  columns: DataTableColumn<T>[];
  data: T[];
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-line bg-white shadow-soft">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[820px] text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-muted">
            <tr>
              {columns.map((column) => (
                <th key={column.key} className="px-5 py-4">
                  {column.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {data.map((item, index) => (
              <tr key={item._id || index}>
                {columns.map((column) => (
                  <td key={column.key} className="px-5 py-4">
                    {column.render(item)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
