import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useResults } from './useResults'
import DataTable from '@/components/DataTable'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Select from '@/components/Select'
import Button from '@/components/Button'
import { EXAM_TYPES } from '@/utils/constants'
import { formatDate, formatMarks } from '@/utils/formatters'
import { Plus } from 'lucide-react'
import type { ResultWithRelations } from './resultsTypes'

export default function ResultsPage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [examType, setExamType] = useState('')
  const { data, isLoading } = useResults(page, { examType: examType || undefined })
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    {
      key: 'student',
      header: 'Student',
      render: (r: ResultWithRelations) => r.students ? `${r.students.first_name} ${r.students.last_name}` : '-',
    },
    {
      key: 'subject',
      header: 'Subject',
      render: (r: ResultWithRelations) => r.teacher_assignments?.subjects?.name ?? '-',
    },
    {
      key: 'class',
      header: 'Class',
      render: (r: ResultWithRelations) => r.teacher_assignments?.classes?.name ?? '-',
    },
    { key: 'exam_type', header: 'Exam Type', render: (r: ResultWithRelations) => r.exam_type },
    { key: 'exam_date', header: 'Date', render: (r: ResultWithRelations) => formatDate(r.exam_date) },
    { key: 'marks', header: 'Marks', render: (r: ResultWithRelations) => formatMarks(r.marks_obtained, r.total_marks) },
    { key: 'grade', header: 'Grade', render: (r: ResultWithRelations) => r.grade ?? '-' },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Results' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Results</h1>
        <Button onClick={() => navigate('/results/new')}>
          <Plus size={16} /> Add Result
        </Button>
      </div>
      <div className="flex gap-4 mb-4">
        <Select
          value={examType}
          onChange={(e) => { setExamType(e.target.value); setPage(1) }}
          options={EXAM_TYPES.map((t) => ({ value: t, label: t }))}
          placeholder="All exam types"
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(r) => r.id}
          onRowClick={(r) => navigate(`/results/${r.id}/edit`)}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
