import type { ReactNode } from 'react'
import Spinner from './Spinner'
import EmptyState from './EmptyState'

interface Column<T> {
  key: string
  header: string
  render?: (item: T) => ReactNode
  className?: string
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  isLoading?: boolean
  keyExtractor: (item: T) => string
  onRowClick?: (item: T) => void
}

export default function DataTable<T>({
  columns,
  data,
  isLoading,
  keyExtractor,
  onRowClick,
}: DataTableProps<T>) {
  if (isLoading) return <Spinner />
  if (data.length === 0) return <EmptyState />

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200">
            {columns.map((col) => (
              <th
                key={col.key}
                className={`text-left py-3 px-4 font-medium text-slate-600 ${col.className ?? ''}`}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((item) => (
            <tr
              key={keyExtractor(item)}
              className={`border-b border-slate-100 hover:bg-slate-50 ${onRowClick ? 'cursor-pointer' : ''}`}
              onClick={() => onRowClick?.(item)}
            >
              {columns.map((col) => (
                <td key={col.key} className={`py-3 px-4 ${col.className ?? ''}`}>
                  {col.render
                    ? col.render(item)
                    : String((item as Record<string, unknown>)[col.key] ?? '-')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
