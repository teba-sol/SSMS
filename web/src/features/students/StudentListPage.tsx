import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useStudents } from './useStudents'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate } from '@/utils/formatters'
import type { Student } from './studentTypes'
import { Plus } from 'lucide-react'

export default function StudentListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useStudents(page, debouncedSearch)
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    { key: 'student_id', header: 'ID' },
    {
      key: 'name',
      header: 'Name',
      render: (s: Student) => `${s.first_name} ${s.middle_name ? s.middle_name + ' ' : ''}${s.last_name}`,
    },
    { key: 'gender', header: 'Gender', render: (s: Student) => s.gender ?? '-' },
    { key: 'date_of_birth', header: 'DOB', render: (s: Student) => formatDate(s.date_of_birth) },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Students' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Students</h1>
        <Button onClick={() => navigate('/students/new')}>
          <Plus size={18} /> Add Student
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search students..."
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
          onRowClick={(s) => navigate(`/students/${s.id}`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
