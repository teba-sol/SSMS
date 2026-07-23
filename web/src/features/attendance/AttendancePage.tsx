import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAttendance } from './useAttendance'
import DataTable from '@/components/DataTable'
import Pagination from '@/components/Pagination'
import Breadcrumb from '@/components/Breadcrumb'
import Select from '@/components/Select'
import Input from '@/components/Input'
import Button from '@/components/Button'
import { ATTENDANCE_STATUSES } from '@/utils/constants'
import { formatDate } from '@/utils/formatters'
import { Plus } from 'lucide-react'
import type { AttendanceWithRelations } from './attendanceTypes'

const statusColors: Record<string, string> = {
  present: 'bg-green-100 text-green-700',
  absent: 'bg-red-100 text-red-700',
  late: 'bg-yellow-100 text-yellow-700',
  excused: 'bg-blue-100 text-blue-700',
}

export default function AttendancePage() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [date, setDate] = useState('')
  const [status, setStatus] = useState('')
  const { data, isLoading } = useAttendance(page, { date: date || undefined, status: status || undefined })
  const totalPages = data ? Math.ceil(data.total / 20) : 1

  const columns = [
    { key: 'date', header: 'Date', render: (a: AttendanceWithRelations) => formatDate(a.date) },
    {
      key: 'student',
      header: 'Student',
      render: (a: AttendanceWithRelations) => a.students ? `${a.students.first_name} ${a.students.last_name}` : '-',
    },
    {
      key: 'class',
      header: 'Class',
      render: (a: AttendanceWithRelations) => a.classes?.name ?? '-',
    },
    {
      key: 'status',
      header: 'Status',
      render: (a: AttendanceWithRelations) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${statusColors[a.status] ?? ''}`}>
          {a.status}
        </span>
      ),
    },
  ]

  return (
    <div>
      <Breadcrumb items={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Attendance' }]} />
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Attendance</h1>
        <Button onClick={() => navigate('/attendance/mark')}>
          <Plus size={16} /> Mark Attendance
        </Button>
      </div>
      <div className="flex gap-4 mb-4">
        <Input
          type="date"
          value={date}
          onChange={(e) => { setDate(e.target.value); setPage(1) }}
        />
        <Select
          value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1) }}
          options={ATTENDANCE_STATUSES.map((s) => ({ value: s, label: s }))}
          placeholder="All statuses"
        />
      </div>
      <div className="bg-white rounded-xl border border-slate-200">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          isLoading={isLoading}
          keyExtractor={(a) => a.id}
        />
        <div className="px-4 pb-4">
          <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
        </div>
      </div>
    </div>
  )
}
