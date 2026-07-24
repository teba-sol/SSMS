import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useActivities, useDeleteActivity } from './useActivities'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import EmptyState from '@/components/EmptyState'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate } from '@/utils/formatters'
import type { ActivityWithRelations } from './activityTypes'
import { Trash2 } from 'lucide-react'

const typeColors: Record<string, string> = {
  sports: 'bg-green-100 text-green-700',
  club: 'bg-blue-100 text-blue-700',
  event: 'bg-purple-100 text-purple-700',
  field_trip: 'bg-orange-100 text-orange-700',
  competition: 'bg-red-100 text-red-700',
  exam: 'bg-yellow-100 text-yellow-700',
}

export default function ActivityListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useActivities(page, debouncedSearch)
  const deleteMutation = useDeleteActivity()
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const handleDelete = (id: string) => {
    if (window.confirm('Are you sure you want to delete this activity?')) {
      deleteMutation.mutate(id)
    }
  }

  const columns = [
    {
      key: 'title',
      header: 'Title',
      render: (a: ActivityWithRelations) => (
        <span className="font-medium text-slate-900">{a.title}</span>
      ),
    },
    {
      key: 'type',
      header: 'Type',
      render: (a: ActivityWithRelations) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${typeColors[a.activity_type] ?? 'bg-slate-100 text-slate-700'}`}>
          {a.activity_type.charAt(0).toUpperCase() + a.activity_type.slice(1)}
        </span>
      ),
    },
    {
      key: 'date',
      header: 'Date',
      render: (a: ActivityWithRelations) => formatDate(a.activity_date),
    },
    {
      key: 'location',
      header: 'Location',
      render: (a: ActivityWithRelations) => a.location ?? '-',
    },
    {
      key: 'class',
      header: 'Class',
      render: (a: ActivityWithRelations) => a.classes?.name ?? 'School-wide',
    },
    {
      key: 'actions',
      header: '',
      render: (a: ActivityWithRelations) => (
        <button
          onClick={(e) => { e.stopPropagation(); handleDelete(a.id) }}
          className="text-red-500 hover:text-red-700 transition-colors"
          title="Delete"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      ),
    },
  ]

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Activities' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Activities</h1>
        <Button onClick={() => navigate('/activities/new')}>Add Activity</Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search activities..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        {data && data.data.length === 0 ? (
          <EmptyState
            title="No activities found"
            message="Get started by creating a new activity."
            action={<Button onClick={() => navigate('/activities/new')}>Add Activity</Button>}
          />
        ) : (
          <>
            <DataTable
              columns={columns}
              data={data?.data ?? []}
              isLoading={isLoading}
              keyExtractor={(a) => a.id}
            />
            <div className="px-4 pb-4">
              <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
            </div>
          </>
        )}
      </div>
    </div>
  )
}
