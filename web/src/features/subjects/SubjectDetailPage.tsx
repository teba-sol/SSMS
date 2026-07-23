import { useParams, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useSubjectDetail } from './useSubjects'
import { subjectService } from './subjectService'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import ErrorMessage from '@/components/ErrorMessage'
import { Card, CardTitle } from '@/components/Card'
import Button from '@/components/Button'
import { formatDate } from '@/utils/formatters'
import { BookOpen, Users, GraduationCap } from 'lucide-react'

export default function SubjectDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading, error } = useSubjectDetail(id!)
  const queryClient = useQueryClient()

  const toggleMutation = useMutation({
    mutationFn: () => subjectService.toggleActive(id!, !data!.subject.is_active),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['subjects', id] })
      queryClient.invalidateQueries({ queryKey: ['subjects'] })
    },
  })

  if (isLoading) return <Spinner />
  if (error) return <ErrorMessage message={error.message} />
  if (!data) return <ErrorMessage message="Subject not found" />

  const { subject, teachers, classes } = data

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Subjects', to: '/subjects' },
          { label: subject.name },
        ]}
      />
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{subject.name}</h1>
          <p className="text-sm text-slate-500 mt-1">{subject.code}</p>
        </div>
        <div className="flex gap-3">
          <Button onClick={() => navigate(`/subjects/${subject.id}/edit`)}>Edit Subject</Button>
          <Button
            variant="secondary"
            onClick={() => {
              if (window.confirm(subject.is_active ? 'Deactivate this subject?' : 'Activate this subject?')) {
                toggleMutation.mutate()
              }
            }}
            isLoading={toggleMutation.isPending}
          >
            {subject.is_active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">{subject.code}</p>
              <p className="text-xs text-slate-500">Subject Code</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{teachers.length}</p>
              <p className="text-xs text-slate-500">Teachers</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <GraduationCap className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900">{classes.length}</p>
              <p className="text-xs text-slate-500">Classes</p>
            </div>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <Card>
          <CardTitle>Subject Information</CardTitle>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between">
              <dt className="text-slate-500">Name</dt>
              <dd className="font-medium">{subject.name}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Code</dt>
              <dd className="font-medium">{subject.code}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Description</dt>
              <dd className="font-medium text-right max-w-xs">{subject.description ?? '-'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Status</dt>
              <dd>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${subject.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                  {subject.is_active ? 'Active' : 'Inactive'}
                </span>
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Created</dt>
              <dd className="font-medium">{formatDate(subject.created_at)}</dd>
            </div>
          </dl>
        </Card>

        <Card>
          <CardTitle>Teachers Teaching This Subject</CardTitle>
          <div className="mt-4 space-y-2">
            {teachers.length === 0 ? (
              <p className="text-sm text-slate-400">No teachers assigned</p>
            ) : (
              teachers.map((t) => (
                <div
                  key={t.id}
                  className="flex items-center justify-between p-3 bg-slate-50 rounded-lg cursor-pointer hover:bg-slate-100"
                  onClick={() => navigate(`/teachers/${t.id}`)}
                >
                  <div>
                    <p className="text-sm font-medium text-slate-700">{t.name}</p>
                    <p className="text-xs text-slate-500">{t.email}</p>
                  </div>
                  <span className="text-xs text-slate-400">{t.employee_id}</span>
                </div>
              ))
            )}
          </div>
        </Card>
      </div>

      <Card>
        <CardTitle>Classes Using This Subject</CardTitle>
        <div className="mt-4 space-y-2">
          {classes.length === 0 ? (
            <p className="text-sm text-slate-400">No classes assigned</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-slate-200">
                    <th className="text-left py-3 px-4 font-medium text-slate-600">Class Name</th>
                    <th className="text-left py-3 px-4 font-medium text-slate-600">Grade</th>
                    <th className="text-left py-3 px-4 font-medium text-slate-600">Section</th>
                  </tr>
                </thead>
                <tbody>
                  {classes.map((c) => (
                    <tr
                      key={c.id}
                      className="border-b border-slate-100 hover:bg-slate-50 cursor-pointer"
                      onClick={() => navigate(`/classes/${c.id}`)}
                    >
                      <td className="py-3 px-4 font-medium text-slate-900">{c.name}</td>
                      <td className="py-3 px-4 text-slate-700">Grade {c.grade_level}</td>
                      <td className="py-3 px-4 text-slate-500">{c.section ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </Card>
    </div>
  )
}
