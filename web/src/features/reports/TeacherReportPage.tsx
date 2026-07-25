import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import { Card } from '@/components/Card'
import Spinner from '@/components/Spinner'

export default function TeacherReportPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['report-teachers'],
    queryFn: async () => {
      const [total, active, assignments] = await Promise.all([
        supabase.from('teachers').select('id', { count: 'exact', head: true }),
        supabase.from('teachers').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('teacher_assignments').select('id', { count: 'exact', head: true }),
      ])
      return {
        total: total.count ?? 0,
        active: active.count ?? 0,
        assignments: assignments.count ?? 0,
      }
    },
  })

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports', to: '/reports' }, { label: 'Teachers' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Teacher Report</h1>
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Total Teachers', value: stats?.total ?? 0, color: 'text-slate-900' },
          { label: 'Active', value: stats?.active ?? 0, color: 'text-green-600' },
          { label: 'Assignments', value: stats?.assignments ?? 0, color: 'text-blue-600' },
        ].map((s) => (
          <Card key={s.label}>
            <p className="text-sm text-slate-500">{s.label}</p>
            <p className={`text-3xl font-bold mt-1 ${s.color}`}>{s.value}</p>
          </Card>
        ))}
      </div>
    </div>
  )
}
