import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/supabase/client'
import Breadcrumb from '@/components/Breadcrumb'
import { Card } from '@/components/Card'
import Spinner from '@/components/Spinner'

export default function ResultsReportPage() {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['report-results'],
    queryFn: async () => {
      const [total, midterm, final, quiz] = await Promise.all([
        supabase.from('results').select('id', { count: 'exact', head: true }),
        supabase.from('results').select('id', { count: 'exact', head: true }).eq('exam_type', 'midterm'),
        supabase.from('results').select('id', { count: 'exact', head: true }).eq('exam_type', 'final'),
        supabase.from('results').select('id', { count: 'exact', head: true }).eq('exam_type', 'quiz'),
      ])
      return {
        total: total.count ?? 0,
        midterm: midterm.count ?? 0,
        final: final.count ?? 0,
        quiz: quiz.count ?? 0,
      }
    },
  })

  if (isLoading) return <Spinner />

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports', to: '/reports' }, { label: 'Results' }]} />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Results Report</h1>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Results', value: stats?.total ?? 0, color: 'text-slate-900' },
          { label: 'Midterm', value: stats?.midterm ?? 0, color: 'text-blue-600' },
          { label: 'Final', value: stats?.final ?? 0, color: 'text-green-600' },
          { label: 'Quiz', value: stats?.quiz ?? 0, color: 'text-purple-600' },
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
