import { useAuth } from '@/hooks/useAuth'
import { LogOut, Bell } from 'lucide-react'

export default function Header() {
  const { profile, signOut } = useAuth()

  return (
    <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-6">
      <div />
      <div className="flex items-center gap-4">
        <button className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-50">
          <Bell size={20} />
        </button>
        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="text-sm font-medium text-slate-900">
              {profile?.first_name} {profile?.last_name}
            </p>
            <p className="text-xs text-slate-500">Administrator</p>
          </div>
          <div className="h-9 w-9 rounded-full bg-primary-100 flex items-center justify-center">
            <span className="text-sm font-semibold text-primary-600">
              {profile?.first_name?.[0]?.toUpperCase()}
            </span>
          </div>
        </div>
        <button
          onClick={() => signOut()}
          className="p-2 text-slate-400 hover:text-red-600 rounded-lg hover:bg-slate-50"
          title="Sign Out"
        >
          <LogOut size={20} />
        </button>
      </div>
    </header>
  )
}
