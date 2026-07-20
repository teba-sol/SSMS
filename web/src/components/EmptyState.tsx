import type { ReactNode } from 'react'
import { Inbox } from 'lucide-react'

interface EmptyStateProps {
  title?: string
  message?: string
  action?: ReactNode
}

export default function EmptyState({
  title = 'No data',
  message = 'Nothing to show here yet.',
  action,
}: EmptyStateProps) {
  return (
    <div className="text-center py-12">
      <Inbox className="h-12 w-12 text-slate-300 mx-auto" />
      <h3 className="mt-4 text-lg font-medium text-slate-900">{title}</h3>
      <p className="mt-2 text-sm text-slate-500">{message}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  )
}
