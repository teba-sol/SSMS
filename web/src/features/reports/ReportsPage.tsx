import Breadcrumb from '@/components/Breadcrumb'
import { Link } from 'react-router-dom'
import { ClipboardCheck, BarChart3, Users, GraduationCap } from 'lucide-react'

const reports = [
  { title: 'Attendance Report', description: 'View attendance summaries by class, student, or date range.', icon: ClipboardCheck, to: '/reports/attendance', color: 'bg-blue-100 text-blue-600' },
  { title: 'Results Report', description: 'Analyze exam results, grades, and class performance.', icon: BarChart3, to: '/reports/results', color: 'bg-green-100 text-green-600' },
  { title: 'Student Report', description: 'Student enrollment stats, attendance, and academic overview.', icon: Users, to: '/reports/students', color: 'bg-purple-100 text-purple-600' },
  { title: 'Teacher Report', description: 'Teacher assignments, workload, and activity overview.', icon: GraduationCap, to: '/reports/teachers', color: 'bg-orange-100 text-orange-600' },
]

export default function ReportsPage() {
  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Reports</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {reports.map((r) => (
          <Link key={r.title} to={r.to} className="bg-white rounded-xl border border-slate-200 p-6 hover:shadow-md transition-shadow">
            <div className="flex items-start gap-4">
              <div className={`${r.color} p-3 rounded-lg`}>
                <r.icon size={24} />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-slate-900">{r.title}</h3>
                <p className="text-sm text-slate-500 mt-1">{r.description}</p>
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  )
}
