import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import { Card } from '@/components/Card'
import Spinner from '@/components/Spinner'

export default function StudentReportPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['report-students'],
    queryFn: async () => {
      const [total, active, enrolled, male, female] = await Promise.all([
        supabase.from('students').select('id', { count: 'exact', head: true }),
        supabase.from('students').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('student_enrollments').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('students').select('id', { count: 'exact', head: true }).eq('gender', 'male'),
        supabase.from('students').select('id', { count: 'exact', head: true }).eq('gender', 'female'),
      ])
      return {
        total: total.count ?? 0,
        active: active.count ?? 0,
        enrolled: enrolled.count ?? 0,
        male: male.count ?? 0,
        female: female.count ?? 0,
      }
    },
  })

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports', to: '/reports' }, { label: 'Students' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Student Report</h1>
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        {[
          { label: 'Total Students', value: stats?.total ?? 0, color: 'text-slate-900' },
          { label: 'Active', value: stats?.active ?? 0, color: 'text-green-600' },
          { label: 'Enrolled', value: stats?.enrolled ?? 0, color: 'text-blue-600' },
          { label: 'Male', value: stats?.male ?? 0, color: 'text-purple-600' },
          { label: 'Female', value: stats?.female ?? 0, color: 'text-pink-600' },
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
