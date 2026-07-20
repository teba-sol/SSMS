import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useStudentEnrollments, useDeleteStudentEnrollment } from './useStudentEnrollments'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import EmptyState from '@/components/EmptyState'
import { useDebounce } from '@/hooks/useDebounce'
import { formatDate } from '@/utils/formatters'
import type { StudentEnrollmentWithRelations } from './studentEnrollmentTypes'
import { Trash2 } from 'lucide-react'

const statusStyles: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  transferred: 'bg-yellow-100 text-yellow-700',
  withdrawn: 'bg-red-100 text-red-700',
  graduated: 'bg-blue-100 text-blue-700',
}

export default function StudentEnrollmentListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useStudentEnrollments(page, debouncedSearch)
  const deleteMutation = useDeleteStudentEnrollment()
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const handleDelete = (id: string) => {
    if (window.confirm('Are you sure you want to delete this enrollment?')) {
      deleteMutation.mutate(id)
    }
  }

  const columns = [
    {
      key: 'student',
      header: 'Student',
      render: (e: StudentEnrollmentWithRelations) =>
        e.students
          ? `${e.students.first_name} ${e.students.last_name} (${e.students.student_id})`
          : '-',
    },
    {
      key: 'class',
      header: 'Class',
      render: (e: StudentEnrollmentWithRelations) => (e.classes ? e.classes.name : '-'),
    },
    {
      key: 'enrollment_date',
      header: 'Enrollment Date',
      render: (e: StudentEnrollmentWithRelations) => formatDate(e.enrollment_date),
    },
    {
      key: 'status',
      header: 'Status',
      render: (e: StudentEnrollmentWithRelations) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${statusStyles[e.status] ?? 'bg-slate-100 text-slate-700'}`}>
          {e.status.charAt(0).toUpperCase() + e.status.slice(1)}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (e: StudentEnrollmentWithRelations) => (
        <button
          onClick={(ev) => { ev.stopPropagation(); handleDelete(e.id) }}
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
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Student Enrollments' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Student Enrollments</h1>
        <Button onClick={() => navigate('/student-enrollments/new')}>
          Add Enrollment
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search by student name, ID, or class..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        {data && data.data.length === 0 ? (
          <EmptyState
            title="No enrollments found"
            message="Get started by creating a new enrollment."
            action={<Button onClick={() => navigate('/student-enrollments/new')}>Add Enrollment</Button>}
          />
        ) : (
          <>
            <DataTable
              columns={columns}
              data={data?.data ?? []}
              isLoading={isLoading}
              keyExtractor={(e) => e.id}
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
