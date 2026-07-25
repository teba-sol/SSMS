import { useNavigate } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { useConversations } from './useMessages'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import EmptyState from '@/components/EmptyState'
import { formatDate } from '@/utils/formatters'
import { MessageSquare } from 'lucide-react'

export default function MessageListPage() {
  const { profile } = useAuth()
  const navigate = useNavigate()
  const { data: conversations = [], isLoading } = useConversations(profile?.id ?? '')

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Messages' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Messages</h1>
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        {conversations.length === 0 ? (
          <EmptyState
            title="No conversations"
            message="Start a conversation from a teacher or parent profile."
          />
        ) : (
          <div className="divide-y divide-slate-100">
            {conversations.map((c: any) => {
              const other = c.participant1?.id === profile?.id ? c.participant2 : c.participant1
              return (
                <div key={c.id} onClick={() => navigate(`/messages/${c.id}`)} className="flex items-center gap-4 p-4 hover:bg-slate-50 cursor-pointer transition-colors">
                  <div className="h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                    <span className="text-sm font-semibold text-primary-600">
                      {other?.first_name?.[0]?.toUpperCase()}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium text-slate-900">{other?.first_name} {other?.last_name}</p>
                      <span className="text-xs text-slate-400">{c.last_message_at ? formatDate(c.last_message_at) : ''}</span>
                    </div>
                    <p className="text-xs text-slate-500 capitalize">{other?.role}</p>
                  </div>
                  <MessageSquare size={16} className="text-slate-300" />
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
