import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTeachers } from './useTeachers'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { useDebounce } from '@/hooks/useDebounce'
import type { TeacherWithProfile } from './teacherTypes'


export default function TeacherListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useTeachers(page, debouncedSearch)
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    { key: 'employee_id', header: 'Employee ID' },
    {
      key: 'name',
      header: 'Name',
      render: (t: TeacherWithProfile) => t.profiles ? `${t.profiles.first_name} ${t.profiles.last_name}` : '-',
    },
    { key: 'department', header: 'Department', render: (t: TeacherWithProfile) => t.department ?? '-' },
    {
      key: 'status',
      header: 'Status',
      render: (t: TeacherWithProfile) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${t.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {t.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Teachers' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Teachers</h1>
        <Button onClick={() => navigate('/teachers/new')}>
          Add Teacher
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search teachers..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(t) => t.id}
          onRowClick={(t) => navigate(`/teachers/${t.id}`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
