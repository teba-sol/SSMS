import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAnnouncements, useDeleteAnnouncement, useTogglePublished } from './useAnnouncements'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { Plus, Trash2, Edit } from 'lucide-react'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate } from '@/utils/formatters'
import type { AnnouncementWithAuthor } from './announcementTypes'

const priorityConfig: Record<string, { bg: string; text: string }> = {
  low: { bg: 'bg-slate-100', text: 'text-slate-600' },
  normal: { bg: 'bg-blue-100', text: 'text-blue-700' },
  high: { bg: 'bg-orange-100', text: 'text-orange-700' },
  urgent: { bg: 'bg-red-100', text: 'text-red-700' },
}

export default function AnnouncementListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useAnnouncements(page, debouncedSearch)
  const deleteMutation = useDeleteAnnouncement()
  const togglePublished = useTogglePublished()
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const handleDelete = (e: React.MouseEvent, id: string) => {
    e.stopPropagation()
    if (window.confirm('Are you sure you want to delete this announcement?')) {
      deleteMutation.mutate(id)
    }
  }

  const handleTogglePublished = (e: React.MouseEvent, id: string, current: boolean) => {
    e.stopPropagation()
    togglePublished.mutate({ id, isPublished: !current })
  }

  const columns = [
    {
      key: 'title',
      header: 'Title',
      render: (a: AnnouncementWithAuthor) => (
        <span className="font-medium text-slate-900">{a.title}</span>
      ),
    },
    {
      key: 'target_audience',
      header: 'Target',
      render: (a: AnnouncementWithAuthor) => (
        <span className="capitalize">{a.target_audience}</span>
      ),
    },
    {
      key: 'priority',
      header: 'Priority',
      render: (a: AnnouncementWithAuthor) => {
        const c = priorityConfig[a.priority] ?? priorityConfig.normal
        return (
          <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${c.bg} ${c.text}`}>
            {a.priority}
          </span>
        )
      },
    },
    {
      key: 'is_published',
      header: 'Published',
      render: (a: AnnouncementWithAuthor) => (
        <button
          onClick={(e) => handleTogglePublished(e, a.id, a.is_published)}
          className={`px-2 py-0.5 rounded-full text-xs font-medium cursor-pointer ${
            a.is_published ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'
          }`}
        >
          {a.is_published ? 'Published' : 'Draft'}
        </button>
      ),
    },
    {
      key: 'author',
      header: 'Author',
      render: (a: AnnouncementWithAuthor) =>
        a.profiles ? `${a.profiles.first_name} ${a.profiles.last_name}` : '-',
    },
    {
      key: 'created_at',
      header: 'Date',
      render: (a: AnnouncementWithAuthor) => formatDate(a.created_at),
    },
    {
      key: 'actions',
      header: '',
      className: 'w-24',
      render: (a: AnnouncementWithAuthor) => (
        <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
          <button
            onClick={() => navigate(`/announcements/${a.id}/edit`)}
            className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            <Edit className="h-4 w-4" />
          </button>
          <button
            onClick={(e) => handleDelete(e, a.id)}
            className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Announcements' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Announcements</h1>
        <Button onClick={() => navigate('/announcements/new')}>
          <Plus className="w-4 h-4 mr-2" />
          New Announcement
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search announcements..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(a) => a.id}
          onRowClick={(a) => navigate(`/announcements/${a.id}/edit`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
