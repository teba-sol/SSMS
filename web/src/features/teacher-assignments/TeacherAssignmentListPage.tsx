import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTeacherAssignments, useDeleteTeacherAssignment } from './useTeacherAssignments'
import DataTable from '@/components/DataTable'
import Input from '@/components/Input'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import EmptyState from '@/components/EmptyState'
import { useDebounce } from '@/hooks/useDebounce'
import type { TeacherAssignmentWithRelations } from './teacherAssignmentTypes'
import { Trash2, Eye } from 'lucide-react'

export default function TeacherAssignmentListPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebounce(search)
  const { data, isLoading } = useTeacherAssignments(page, debouncedSearch)
  const deleteMutation = useDeleteTeacherAssignment()
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const handleDelete = (id: string) => {
    if (window.confirm('Are you sure you want to delete this assignment?')) {
      deleteMutation.mutate(id)
    }
  }

  const columns = [
    {
      key: 'teacher',
      header: 'Teacher',
      render: (t: TeacherAssignmentWithRelations) =>
        t.teachers ? `${t.teachers.profiles.first_name} ${t.teachers.profiles.last_name}` : '-',
    },
    {
      key: 'class',
      header: 'Class',
      render: (t: TeacherAssignmentWithRelations) => (t.classes ? t.classes.name : '-'),
    },
    {
      key: 'subject',
      header: 'Subject',
      render: (t: TeacherAssignmentWithRelations) =>
        t.subjects ? `${t.subjects.name} (${t.subjects.code})` : '-',
    },
    {
      key: 'academic_year',
      header: 'Academic Year',
      render: (t: TeacherAssignmentWithRelations) => (t.academic_years ? t.academic_years.name : '-'),
    },
    {
      key: 'actions',
      header: 'Actions',
      render: (t: TeacherAssignmentWithRelations) => (
        <div className="flex items-center gap-2">
          {t.teachers && (
            <button
              onClick={(e) => { e.stopPropagation(); navigate(`/teachers/${t.teachers.id}`) }}
              className="text-slate-400 hover:text-primary-600 transition-colors"
              title="View Teacher"
            >
              <Eye className="h-4 w-4" />
            </button>
          )}
          <button
            onClick={(e) => { e.stopPropagation(); handleDelete(t.id) }}
            className="text-red-500 hover:text-red-700 transition-colors"
            title="Delete"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      ),
    },
  ]

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Teacher Assignments' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Teacher Assignments</h1>
        <Button onClick={() => navigate('/teacher-assignments/new')}>
          Add Assignment
        </Button>
      </div>
      <div className="mb-4">
        <Input
          placeholder="Search by teacher, class, or subject..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        {data && data.data.length === 0 ? (
          <EmptyState
            title="No assignments found"
            message="Get started by creating a new teacher assignment."
            action={<Button onClick={() => navigate('/teacher-assignments/new')}>Add Assignment</Button>}
          />
        ) : (
          <>
            <DataTable
              columns={columns}
              data={data?.data ?? []}
              isLoading={isLoading}
              keyExtractor={(t) => t.id}
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
