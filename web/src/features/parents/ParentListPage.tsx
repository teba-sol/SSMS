import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useParents } from './useParents'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { useDebounce } from '@/hooks/useDebounce'
import type { ParentWithStudents } from './parentTypes'

export default function ParentListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useParents(page, debouncedSearch)
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    {
      key: 'name',
      header: 'Name',
      render: (p: ParentWithStudents) => `${p.first_name} ${p.last_name}`,
    },
    { key: 'email', header: 'Email' },
    { key: 'phone', header: 'Phone', render: (p: ParentWithStudents) => p.phone ?? '-' },
    {
      key: 'children',
      header: 'Children',
      render: (p: ParentWithStudents) =>
        p.parent_students?.map((ps) => ps.students ? `${ps.students.first_name} ${ps.students.last_name}` : '').filter(Boolean).join(', ') ?? '-',
    },
    {
      key: 'status',
      header: 'Status',
      render: (p: ParentWithStudents) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {p.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Parents' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Parents</h1>
        <Button onClick={() => navigate('/parents/new')}>
          <Plus size={18} /> Add Parent
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search parents..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(p) => p.id}
          onRowClick={(p) => navigate(`/parents/${p.id}`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
