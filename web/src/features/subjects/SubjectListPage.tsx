import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useSubjects } from './useSubjects'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { Plus } from 'lucide-react'
import { useDebounce } from '@/hooks/useDebounce'
import type { Subject } from './subjectTypes'

export default function SubjectListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useSubjects(page, debouncedSearch)
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    { key: 'code', header: 'Code' },
    { key: 'name', header: 'Name' },
    {
      key: 'description',
      header: 'Description',
      render: (s: Subject) => s.description ?? '-',
    },
    {
      key: 'status',
      header: 'Status',
      render: (s: Subject) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${s.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {s.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Subjects' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Subjects</h1>
        <Button onClick={() => navigate('/subjects/new')}>
          <Plus className="w-4 h-4 mr-2" />
          Add Subject
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search subjects..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(s) => s.id}
          onRowClick={(s) => navigate(`/subjects/${s.id}`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
