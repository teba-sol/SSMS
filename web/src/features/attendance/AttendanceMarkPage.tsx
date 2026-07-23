import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/supabase/client'
import { useQuery, useMutation } from '@tanstack/react-query'
import Breadcrumb from '@/components/Breadcrumb'
import Input from '@/components/Input'
import Select from '@/components/Select'
import Button from '@/components/Button'
import Spinner from '@/components/Spinner'
import { attendanceService } from './attendanceService'
import { useAuth } from '@/contexts/AuthContext'
import { ATTENDANCE_STATUSES } from '@/utils/constants'

function getToday() {
  return new Date().toISOString().split('T')[0]
}

interface EnrolledStudent {
  student_id: string
  students: { id: string; first_name: string; last_name: string; student_id: string } | null
}

export default function AttendanceMarkPage() {
  const navigate = useNavigate()
  const { profile } = useAuth()
  const [classId, setClassId] = useState('')
  const [date, setDate] = useState(getToday())
  const [statuses, setStatuses] = useState<Record<string, string>>({})
  const [successMsg, setSuccessMsg] = useState('')
  const [errorMsg, setErrorMsg] = useState('')

  const { data: classes } = useQuery({
    queryKey: ['classes'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('classes')
        .select('id, name, grade_level, section')
        .eq('is_active', true)
        .order('grade_level')
      if (error) throw error
      return data
    },
  })

  const { data: students, isLoading: studentsLoading } = useQuery({
    queryKey: ['enrolled-students', classId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('student_enrollments')
        .select('student_id, students(id, first_name, last_name, student_id)')
        .eq('class_id', classId)
        .eq('status', 'active')
      if (error) throw error
      return (data as any[]).map((row) => ({
        student_id: row.student_id as string,
        students: Array.isArray(row.students) ? row.students[0] as { id: string; first_name: string; last_name: string; student_id: string } | undefined : row.students as { id: string; first_name: string; last_name: string; student_id: string } | undefined,
      })) as EnrolledStudent[]
    },
    enabled: !!classId,
  })

  const { data: existingAttendance } = useQuery({
    queryKey: ['attendance', classId, date],
    queryFn: () => attendanceService.getByClassAndDate(classId, date),
    enabled: !!classId && !!date,
  })

  useEffect(() => {
    if (students && existingAttendance) {
      const map: Record<string, string> = {}
      for (const s of students) {
        const existing = existingAttendance.find((a) => a.student_id === s.student_id)
        map[s.student_id] = existing?.status || 'present'
      }
      setStatuses(map)
    } else if (students) {
      const map: Record<string, string> = {}
      for (const s of students) {
        map[s.student_id] = 'present'
      }
      setStatuses(map)
    }
  }, [students, existingAttendance])

  const saveMutation = useMutation({
    mutationFn: (records: Parameters<typeof attendanceService.upsert>[0]) =>
      attendanceService.upsert(records),
    onSuccess: () => {
      setSuccessMsg('Attendance saved successfully!')
      setErrorMsg('')
      setTimeout(() => navigate('/attendance'), 1200)
    },
    onError: (err: Error) => {
      setErrorMsg(err.message || 'Failed to save attendance')
      setSuccessMsg('')
    },
  })

  const handleStatusChange = (studentId: string, status: string) => {
    setStatuses((prev) => ({ ...prev, [studentId]: status }))
  }

  const handleSave = () => {
    if (!classId || !date || !students) return
    setSuccessMsg('')
    setErrorMsg('')
    const records = students.map((s) => ({
      student_id: s.student_id,
      class_id: classId,
      date,
      status: statuses[s.student_id] || 'present',
      marked_by: profile?.id || '',
    }))
    saveMutation.mutate(records)
  }

  return (
    <div>
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Attendance', to: '/attendance' },
          { label: 'Mark Attendance' },
        ]}
      />
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Mark Attendance</h1>

      {successMsg && (
        <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm">
          {successMsg}
        </div>
      )}
      {errorMsg && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {errorMsg}
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
        <div className="grid grid-cols-2 gap-4 max-w-xl">
          <Select
            label="Class"
            value={classId}
            onChange={(e) => {
              setClassId(e.target.value)
              setStatuses({})
            }}
            options={
              classes?.map((c) => ({
                value: c.id,
                label: `${c.name}${c.section ? ` - ${c.section}` : ''}`,
              })) ?? []
            }
            placeholder="Select class..."
          />
          <Input
            label="Date"
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
        </div>

        {classId && date && (
          <>
            {studentsLoading ? (
              <div className="flex justify-center py-10">
                <Spinner />
              </div>
            ) : students && students.length > 0 ? (
              <div className="space-y-2">
                <div className="grid grid-cols-[1fr_200px] gap-4 px-4 py-2 text-sm font-medium text-slate-500 border-b border-slate-200">
                  <span>Student</span>
                  <span>Status</span>
                </div>
                {students.map((s) => (
                  <div
                    key={s.student_id}
                    className="grid grid-cols-[1fr_200px] gap-4 items-center px-4 py-2 rounded-lg hover:bg-slate-50"
                  >
                    <span className="text-sm text-slate-900">
                      {s.students
                        ? `${s.students.last_name}, ${s.students.first_name}`
                        : s.student_id}
                    </span>
                    <Select
                      value={statuses[s.student_id] || 'present'}
                      onChange={(e) => handleStatusChange(s.student_id, e.target.value)}
                      options={ATTENDANCE_STATUSES.map((st) => ({
                        value: st,
                        label: st.charAt(0).toUpperCase() + st.slice(1),
                      }))}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-slate-500 text-center py-8">
                No students enrolled in this class.
              </p>
            )}

            {students && students.length > 0 && (
              <div className="flex gap-3 pt-4 border-t border-slate-200">
                <Button
                  onClick={handleSave}
                  isLoading={saveMutation.isPending}
                >
                  Save Attendance
                </Button>
                <Button
                  variant="secondary"
                  onClick={() => navigate('/attendance')}
                >
                  Cancel
                </Button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}
