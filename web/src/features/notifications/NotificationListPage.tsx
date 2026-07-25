import { useState } from 'react'
import { useNotifications, useMarkAllNotificationsRead } from './useNotifications'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import EmptyState from '@/components/EmptyState'
import { formatDate } from '@/utils/formatters'
import type { Notification } from './notificationTypes'
import { Bell, CheckCheck } from 'lucide-react'

const typeIcons: Record<string, string> = {
  attendance: 'bg-red-100 text-red-600',
  result: 'bg-blue-100 text-blue-600',
  announcement: 'bg-purple-100 text-purple-600',
  enrollment: 'bg-green-100 text-green-600',
  system: 'bg-slate-100 text-slate-600',
}

export default function NotificationListPage() {
  const [page, setPage] = useState(1)
  const { data, isLoading } = useNotifications(page)
  const markAllRead = useMarkAllNotificationsRead()
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Notifications' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Notifications</h1>
        <Button variant="secondary" onClick={() => markAllRead.mutate()} isLoading={markAllRead.isPending}>
          <CheckCheck size={16} /> Mark All as Read
        </Button>
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        {data && data.data.length === 0 ? (
          <EmptyState title="No notifications" message="You're all caught up!" />
        ) : (
          <div className="divide-y divide-slate-100">
            {data?.data.map((n: Notification) => (
              <div key={n.id} className={`flex items-start gap-4 p-4 hover:bg-slate-50 transition-colors ${!n.is_read ? 'bg-primary-50/30' : ''}`}>
                <div className={`p-2 rounded-lg ${typeIcons[n.type] ?? 'bg-slate-100 text-slate-600'}`}>
                  <Bell size={16} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className={`text-sm ${!n.is_read ? 'font-semibold text-slate-900' : 'font-medium text-slate-700'}`}>{n.title}</p>
                    {!n.is_read && <span className="w-2 h-2 rounded-full bg-primary-500" />}
                  </div>
                  <p className="text-sm text-slate-500 mt-0.5">{n.body}</p>
                  <p className="text-xs text-slate-400 mt-1">{formatDate(n.created_at)}</p>
                </div>
              </div>
            ))}
          </div>
        )}
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
