import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  Heart,
  BookOpen,
  ClipboardCheck,
  BarChart3,
  Calendar,
  Megaphone,
  ArrowRightLeft,
  UserPlus,
  School,
  Layers,
  Activity,
  Bell,
  MessageSquare,
  FileText,
  Settings,
} from 'lucide-react'

type NavItem =
  | { to: string; label: string; icon: typeof LayoutDashboard }
  | { label: string; isHeader: true }

const navItems: NavItem[] = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { label: 'School Setup', isHeader: true },
  { to: '/academic-years', label: 'Academic Years', icon: Calendar },
  { to: '/classes', label: 'Classes', icon: Layers },
  { to: '/subjects', label: 'Subjects', icon: BookOpen },
  { label: 'People', isHeader: true },
  { to: '/teachers', label: 'Teachers', icon: GraduationCap },
  { to: '/students', label: 'Students', icon: Users },
  { to: '/parents', label: 'Parents', icon: Heart },
  { label: 'Assignments', isHeader: true },
  { to: '/teacher-assignments', label: 'Teacher Assignments', icon: ArrowRightLeft },
  { to: '/student-enrollments', label: 'Student Enrollments', icon: UserPlus },
  { label: 'Operations', isHeader: true },
  { to: '/attendance', label: 'Attendance', icon: ClipboardCheck },
  { to: '/results', label: 'Results', icon: BarChart3 },
  { to: '/activities', label: 'Activities', icon: Activity },
  { to: '/announcements', label: 'Announcements', icon: Megaphone },
  { label: 'Communication', isHeader: true },
  { to: '/notifications', label: 'Notifications', icon: Bell },
  { to: '/messages', label: 'Messages', icon: MessageSquare },
  { label: 'Reports', isHeader: true },
  { to: '/reports/attendance', label: 'Attendance Reports', icon: FileText },
  { to: '/reports/results', label: 'Results Reports', icon: FileText },
  { to: '/reports/students', label: 'Student Reports', icon: FileText },
  { to: '/reports/teachers', label: 'Teacher Reports', icon: FileText },
  { label: 'System', isHeader: true },
  { to: '/settings', label: 'Settings', icon: Settings },
]

export default function Sidebar() {
  return (
    <aside className="fixed left-0 top-0 h-full w-64 bg-white border-r border-slate-200 flex flex-col">
      <div className="p-6 border-b border-slate-200">
        <h1 className="text-lg font-bold text-slate-900 flex items-center gap-2">
          <School size={20} />
          SSCS Admin
        </h1>
        <p className="text-xs text-slate-500">Student Status Checkup</p>
      </div>

      <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
        {navItems.map((item, i) => {
          if ('isHeader' in item && item.isHeader) {
            return (
              <p key={i} className="text-xs font-semibold text-slate-400 uppercase tracking-wider pt-4 pb-1 px-3">
                {item.label}
              </p>
            )
          }
          const navItem = item as { to: string; label: string; icon: typeof LayoutDashboard }
          return (
            <NavLink
              key={navItem.to}
              to={navItem.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-primary-50 text-primary-600'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                }`
              }
            >
              <navItem.icon size={18} />
              {navItem.label}
            </NavLink>
          )
        })}
      </nav>

      <div className="p-4 border-t border-slate-200">
        <p className="text-xs text-slate-400 text-center">v1.0.0</p>
      </div>
    </aside>
  )
}
