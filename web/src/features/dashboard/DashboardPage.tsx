import { useDashboard } from './useDashboard'
import { Card, CardHeader, CardTitle } from '@/components/Card'
import Spinner from '@/components/Spinner'
import { Link } from 'react-router-dom'
import { Users, GraduationCap, BookOpen, Heart, ClipboardCheck, Calendar, Megaphone, Plus } from 'lucide-react'
import { formatDate } from '@/utils/formatters'

const priorityColors: Record<string, string> = {
  low: 'bg-slate-100 text-slate-600',
  normal: 'bg-blue-100 text-blue-700',
  high: 'bg-orange-100 text-orange-700',
  urgent: 'bg-red-100 text-red-700',
}

export default function DashboardPage() {
  const { data: stats, isLoading } = useDashboard()

  const statCards = [
    { label: 'Students', value: stats?.totalStudents ?? '--', icon: Users, color: 'bg-blue-500', to: '/students' },
    { label: 'Teachers', value: stats?.totalTeachers ?? '--', icon: GraduationCap, color: 'bg-purple-500', to: '/teachers' },
    { label: 'Classes', value: stats?.totalClasses ?? '--', icon: BookOpen, color: 'bg-green-500', to: '/classes' },
    { label: 'Parents', value: stats?.totalParents ?? '--', icon: Heart, color: 'bg-pink-500', to: '/parents' },
    { label: 'Enrollments', value: stats?.totalEnrollments ?? '--', icon: ClipboardCheck, color: 'bg-indigo-500', to: '/enrollments' },
    { label: 'Attendance', value: '--', icon: Calendar, color: 'bg-orange-500', to: '/attendance' },
  ]

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <Spinner />
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
        <p className="text-slate-600">Here's your school overview.</p>
      </div>

      {stats?.currentAcademicYear && (
        <div className="mb-6 flex items-center gap-2 text-sm text-slate-600">
          <Calendar className="h-4 w-4" />
          <span>Current Academic Year: <strong className="text-slate-900">{stats.currentAcademicYear.name}</strong></span>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {statCards.map((stat) => (
          <Link
            key={stat.label}
            to={stat.to}
            className="bg-white rounded-xl border border-slate-200 p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-500">{stat.label}</p>
                <p className="text-2xl font-bold text-slate-900 mt-1">{stat.value}</p>
              </div>
              <div className={`${stat.color} p-3 rounded-lg`}>
                <stat.icon className="h-6 w-6 text-white" />
              </div>
            </div>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Megaphone className="h-5 w-5" />
              Recent Announcements
            </CardTitle>
          </CardHeader>
          {stats?.recentAnnouncements && stats.recentAnnouncements.length > 0 ? (
            <ul className="divide-y divide-slate-100">
              {stats.recentAnnouncements.map((a) => (
                <li key={a.id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-slate-900 text-sm">{a.title}</p>
                    <p className="text-xs text-slate-500 mt-0.5">{formatDate(a.created_at)}</p>
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${priorityColors[a.priority] ?? 'bg-slate-100 text-slate-600'}`}>
                    {a.priority}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-slate-500">No recent announcements.</p>
          )}
          <div className="mt-4">
            <Link to="/announcements" className="text-sm text-primary-500 hover:text-primary-600 font-medium">
              View all announcements &rarr;
            </Link>
          </div>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <Link to="/students/new" className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg hover:bg-slate-50">
              <Plus className="h-4 w-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-900">Add Student</span>
            </Link>
            <Link to="/teachers/new" className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg hover:bg-slate-50">
              <Plus className="h-4 w-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-900">Add Teacher</span>
            </Link>
            <Link to="/classes/new" className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg hover:bg-slate-50">
              <Plus className="h-4 w-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-900">Add Class</span>
            </Link>
            <Link to="/academic-years" className="flex items-center gap-3 p-3 border border-slate-200 rounded-lg hover:bg-slate-50">
              <Calendar className="h-4 w-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-900">Manage Academic Years</span>
            </Link>
          </div>
        </Card>
      </div>
    </div>
  )
}
