import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useClasses } from './useClasses'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { useDebounce } from '@/hooks/useDebounce'
import type { SchoolClassWithYear } from './classTypes'

export default function ClassListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useClasses(page, debouncedSearch)
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    { key: 'name', header: 'Name' },
    { key: 'grade_level', header: 'Grade', render: (c: SchoolClassWithYear) => `Grade ${c.grade_level}` },
    { key: 'section', header: 'Section', render: (c: SchoolClassWithYear) => c.section ?? '-' },
    { key: 'room', header: 'Room', render: (c: SchoolClassWithYear) => c.room ?? '-' },
    { key: 'capacity', header: 'Capacity' },
    { key: 'academic_year', header: 'Academic Year', render: (c: SchoolClassWithYear) => c.academic_years?.name ?? '-' },
    {
      key: 'status',
      header: 'Status',
      render: (c: SchoolClassWithYear) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${c.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {c.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'School', to: '/dashboard' }, { label: 'Classes' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Classes</h1>
        <Button onClick={() => navigate('/classes/new')}>
          Add Class
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search classes..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(c) => c.id}
          onRowClick={(c) => navigate(`/classes/${c.id}`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
