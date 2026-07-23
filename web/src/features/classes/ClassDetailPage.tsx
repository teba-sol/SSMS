import { useParams, useNavigate } from 'react-router-dom'
import { useClassDetail, useToggleClassActive } from './useClasses'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'
import { formatDate } from '@/utils/formatters'
import { Users, BookOpen, GraduationCap, CalendarDays, CheckCircle, XCircle, Clock, AlertCircle } from 'lucide-react'

export default function ClassDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading, error } = useClassDetail(id!)
  const toggleActive = useToggleClassActive()

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage message={error.message} />
  if (!data) return <ErrorMessage message="Class not found" />

  const { schoolClass, studentCount, enrolledStudents, classTeacher, subjects, attendanceSummary } = data

  const handleToggleActive = async () => {
    await toggleActive.mutateAsync({ id: schoolClass.id, isActive: !schoolClass.is_active })
  }

  const capacityPercent = Math.round((studentCount / schoolClass.capacity) * 100)

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Classes', to: '/classes' },
          { label: schoolClass.name },
        ]}
      />
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{schoolClass.name}</h1>
          <p className="text-sm text-slate-500 mt-1">
            Grade {schoolClass.grade_level}{schoolClass.section ? ` - ${schoolClass.section}` : ''}
          </p>
        </div>
        <div className="flex gap-3">
          <Button onClick={() => navigate(`/classes/${schoolClass.id}/edit`)}>Edit Class</Button>
          <Button
            variant="secondary"
            onClick={handleToggleActive}
            isLoading={toggleActive.isPending}
          >
            {schoolClass.is_active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{studentCount}</p>
              <p className="text-xs text-slate-500">Students</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <GraduationCap className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{classTeacher?.name ?? 'Unassigned'}</p>
              <p className="text-xs text-slate-500">Class Teacher</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{subjects.length}</p>
              <p className="text-xs text-slate-500">Subjects</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
              <CalendarDays className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{schoolClass.academic_years?.name ?? '-'}</p>
              <p className="text-xs text-slate-500">Academic Year</p>
            </div>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <Card>
          <CardTitle>Class Information</CardTitle>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between">
              <dt className="text-slate-500">Room</dt>
              <dd className="font-medium">{schoolClass.room ?? '-'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Capacity</dt>
              <dd className="font-medium">{studentCount} / {schoolClass.capacity}</dd>
            </div>
            <div>
              <div className="flex justify-between mb-1">
                <span className="text-xs text-slate-500">Capacity Used</span>
                <span className={`text-xs font-medium ${capacityPercent > 90 ? 'text-red-600' : capacityPercent > 70 ? 'text-amber-600' : 'text-green-600'}`}>
                  {capacityPercent}%
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div
                  className={`h-2 rounded-full ${capacityPercent > 90 ? 'bg-red-500' : capacityPercent > 70 ? 'bg-amber-500' : 'bg-green-500'}`}
                  style={{ width: `${Math.min(capacityPercent, 100)}%` }}
                />
              </div>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Status</dt>
              <dd>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${schoolClass.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                  {schoolClass.is_active ? 'Active' : 'Inactive'}
                </span>
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Created</dt>
              <dd className="font-medium">{formatDate(schoolClass.created_at)}</dd>
            </div>
          </dl>
        </Card>

        <Card>
          <CardTitle>Today's Attendance</CardTitle>
          <div className="mt-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-4 h-4 text-green-500" />
                <span className="text-sm text-slate-600">Present</span>
              </div>
              <span className="text-sm font-bold text-slate-900">{attendanceSummary.present}</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <XCircle className="w-4 h-4 text-red-500" />
                <span className="text-sm text-slate-600">Absent</span>
              </div>
              <span className="text-sm font-bold text-slate-900">{attendanceSummary.absent}</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-amber-500" />
                <span className="text-sm text-slate-600">Late</span>
              </div>
              <span className="text-sm font-bold text-slate-900">{attendanceSummary.late}</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-blue-500" />
                <span className="text-sm text-slate-600">Excused</span>
              </div>
              <span className="text-sm font-bold text-slate-900">{attendanceSummary.excused}</span>
            </div>
            {attendanceSummary.total === 0 && (
              <p className="text-xs text-slate-400 text-center pt-2">No attendance recorded today</p>
            )}
          </div>
        </Card>

        <Card>
          <CardTitle>Subjects Taught</CardTitle>
          <div className="mt-4 space-y-2">
            {subjects.length === 0 ? (
              <p className="text-sm text-slate-400">No subjects assigned</p>
            ) : (
              subjects.map((s) => (
                <div key={s.id} className="flex items-center justify-between p-2 bg-slate-50 rounded-lg">
                  <span className="text-sm font-medium text-slate-700">{s.name}</span>
                  <span className="text-xs text-slate-500">{s.code}</span>
                </div>
              ))
            )}
          </div>
        </Card>
      </div>

      <Card>
        <div className="flex items-center justify-between mb-4">
          <CardTitle>Enrolled Students ({studentCount})</CardTitle>
          <Button variant="secondary" onClick={() => navigate(`/student-enrollments/new?class_id=${schoolClass.id}`)}>
            Enroll Student
          </Button>
        </div>
        {enrolledStudents.length === 0 ? (
          <p className="text-sm text-slate-400 text-center py-8">No students enrolled in this class</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200">
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Student ID</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Name</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Gender</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Enrolled</th>
                </tr>
              </thead>
              <tbody>
                {enrolledStudents.map((e) => {
                  const student = e.students
                  return (
                    <tr
                      key={e.id}
                      className="border-b border-slate-100 hover:bg-slate-50 cursor-pointer"
                      onClick={() => navigate(`/students/${student?.id}`)}
                    >
                      <td className="py-3 px-4 font-medium text-slate-900">{student?.student_id ?? '-'}</td>
                      <td className="py-3 px-4 text-slate-700">
                        {student ? `${student.last_name}, ${student.first_name}` : '-'}
                      </td>
                      <td className="py-3 px-4 text-slate-500">{student?.gender ?? '-'}</td>
                      <td className="py-3 px-4 text-slate-500">{formatDate(e.enrollment_date)}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
