import { useParams, useNavigate } from 'react-router-dom'
import { useTeacherDetail } from './useTeachers'
import { teacherService } from './teacherService'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'
import { formatDate } from '@/utils/formatters'
import { BookOpen, Users, GraduationCap, Mail, Phone, Briefcase, Calendar } from 'lucide-react'

export default function TeacherDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading, error } = useTeacherDetail(id!)
  const queryClient = useQueryClient()

  const toggleMutation = useMutation({
    mutationFn: () => teacherService.toggleActive(id!, !data!.teacher.is_active),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teachers', id] })
      queryClient.invalidateQueries({ queryKey: ['teachers'] })
    },
  })

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage message={error.message} />
  if (!data) return <ErrorMessage message="Teacher not found" />

  const { teacher, assignments, stats } = data
  const profile = teacher.profiles

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Teachers', to: '/teachers' },
          { label: profile ? `${profile.first_name} ${profile.last_name}` : teacher.employee_id },
        ]}
      />
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">
            {profile?.first_name} {profile?.last_name}
          </h1>
          <p className="text-sm text-slate-500 mt-1">{teacher.employee_id}</p>
        </div>
        <div className="flex items-center gap-3">
          <Button onClick={() => navigate(`/teachers/${teacher.id}/edit`)}>Edit Teacher</Button>
          <Button
            variant="secondary"
            onClick={() => navigate(`/teacher-assignments/new?teacher_id=${teacher.id}`)}
          >
            Assign Class
          </Button>
          <Button
            variant={teacher.is_active ? 'danger' : 'primary'}
            onClick={() => {
              if (window.confirm(teacher.is_active ? 'Deactivate this teacher?' : 'Activate this teacher?')) {
                toggleMutation.mutate()
              }
            }}
            isLoading={toggleMutation.isPending}
          >
            {teacher.is_active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.subjectsCount}</p>
              <p className="text-xs text-slate-500">Subjects</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <GraduationCap className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.classesCount}</p>
              <p className="text-xs text-slate-500">Classes</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{stats.studentsCount}</p>
              <p className="text-xs text-slate-500">Students</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
              <Briefcase className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{teacher.department ?? '-'}</p>
              <p className="text-xs text-slate-500">Department</p>
            </div>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <Card>
          <CardTitle>Contact Information</CardTitle>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between items-center">
              <dt className="text-slate-500 flex items-center gap-2"><Mail className="w-4 h-4" /> Email</dt>
              <dd className="font-medium">{profile?.email ?? '-'}</dd>
            </div>
            <div className="flex justify-between items-center">
              <dt className="text-slate-500 flex items-center gap-2"><Phone className="w-4 h-4" /> Phone</dt>
              <dd className="font-medium">{profile?.phone ?? '-'}</dd>
            </div>
            <div className="flex justify-between items-center">
              <dt className="text-slate-500 flex items-center gap-2"><Calendar className="w-4 h-4" /> Hire Date</dt>
              <dd className="font-medium">{teacher.hire_date ? formatDate(teacher.hire_date) : '-'}</dd>
            </div>
            <div className="flex justify-between items-center">
              <dt className="text-slate-500">Qualification</dt>
              <dd className="font-medium">{teacher.qualification ?? '-'}</dd>
            </div>
            <div className="flex justify-between items-center">
              <dt className="text-slate-500">Status</dt>
              <dd>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${teacher.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                  {teacher.is_active ? 'Active' : 'Inactive'}
                </span>
              </dd>
            </div>
          </dl>
        </Card>
      </div>

      <Card>
        <div className="flex items-center justify-between mb-4">
          <CardTitle>Assignments ({assignments.length})</CardTitle>
          <Button variant="secondary" onClick={() => navigate(`/teacher-assignments/new?teacher_id=${teacher.id}`)}>
            Add Assignment
          </Button>
        </div>
        {assignments.length === 0 ? (
          <p className="text-sm text-slate-400 text-center py-8">No assignments yet. Assign subjects and classes to this teacher.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200">
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Class</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Subject</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Academic Year</th>
                </tr>
              </thead>
              <tbody>
                {assignments.map((a) => (
                  <tr key={a.id} className="border-b border-slate-100">
                    <td className="py-3 px-4">
                      {a.classes ? (
                        <span
                          className="font-medium text-slate-900 hover:text-blue-600 cursor-pointer"
                          onClick={() => navigate(`/classes/${a.classes!.id}`)}
                        >
                          {a.classes!.name}
                        </span>
                      ) : '-'}
                    </td>
                    <td className="py-3 px-4">
                      {a.subjects ? (
                        <span
                          className="text-slate-700 hover:text-blue-600 cursor-pointer"
                          onClick={() => navigate(`/subjects/${a.subjects!.id}`)}
                        >
                          {a.subjects!.name}
                        </span>
                      ) : '-'}
                    </td>
                    <td className="py-3 px-4 text-slate-500">
                      {a.academic_years?.name ?? '-'}
                      {a.academic_years?.is_current && (
                        <span className="ml-2 px-1.5 py-0.5 bg-green-100 text-green-700 rounded text-xs">Current</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
