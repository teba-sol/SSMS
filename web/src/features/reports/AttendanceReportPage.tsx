import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import { Card } from '@/components/Card'
import Spinner from '@/components/Spinner'
import { formatDate } from '@/utils/formatters'

export default function AttendanceReportPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['report-attendance'],
    queryFn: async () => {
      const today = new Date().toISOString().split('T')[0]
      const [total, present, absent, late, excused] = await Promise.all([
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'present'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'absent'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'late'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'excused'),
      ])
      return {
        date: today,
        total: total.count ?? 0,
        present: present.count ?? 0,
        absent: absent.count ?? 0,
        late: late.count ?? 0,
        excused: excused.count ?? 0,
      }
    },
  })

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports', to: '/reports' }, { label: 'Attendance' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Attendance Report</h1>
      <p className="text-sm text-slate-500 mb-4">Date: {formatDate(stats?.date ?? new Date().toISOString())}</p>
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
        {[
          { label: 'Total Records', value: stats?.total ?? 0, color: 'text-slate-900' },
          { label: 'Present', value: stats?.present ?? 0, color: 'text-green-600' },
          { label: 'Absent', value: stats?.absent ?? 0, color: 'text-red-600' },
          { label: 'Late', value: stats?.late ?? 0, color: 'text-yellow-600' },
          { label: 'Excused', value: stats?.excused ?? 0, color: 'text-blue-600' },
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
