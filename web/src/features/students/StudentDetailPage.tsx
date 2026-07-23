import { useParams, useNavigate } from 'react-router-dom'
import { useStudent } from './useStudents'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { formatDate } from '@/utils/formatters'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'

export default function StudentDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: student, isLoading, error } = useStudent(id!)

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage message={error.message} />
  if (!student) return <ErrorMessage message="Student not found" />

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Students', to: '/students' },
          { label: `${student.first_name} ${student.last_name}` },
        ]}
      />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">
          {student.first_name} {student.middle_name} {student.last_name}
        </h1>
        <div className="flex items-center gap-3">
          <Button variant="secondary" onClick={() => navigate('/students')}>Back</Button>
          <Button onClick={() => navigate(`/students/${id}/edit`)}>Edit</Button>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardTitle>Personal Information</CardTitle>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between"><dt className="text-slate-500">Student ID</dt><dd className="font-medium">{student.student_id}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Date of Birth</dt><dd className="font-medium">{formatDate(student.date_of_birth)}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Gender</dt><dd className="font-medium capitalize">{student.gender ?? '-'}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Address</dt><dd className="font-medium">{student.address ?? '-'}</dd></div>
          </dl>
        </Card>
        <Card>
          <CardTitle>Emergency Contact</CardTitle>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between"><dt className="text-slate-500">Contact Name</dt><dd className="font-medium">{student.emergency_contact ?? '-'}</dd></div>
            <div className="flex justify-between"><dt className="text-slate-500">Phone</dt><dd className="font-medium">{student.emergency_phone ?? '-'}</dd></div>
          </dl>
        </Card>
      </div>
    </div>
  )
}
