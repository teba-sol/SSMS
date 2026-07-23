export interface Attendance {
  id: string
  student_id: string
  class_id: string
  date: string
  status: 'present' | 'absent' | 'late' | 'excused'
  marked_by: string
  notes: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface AttendanceWithRelations extends Attendance {
  students?: { first_name: string; last_name: string; student_id: string }
  classes?: { name: string; grade_level: number; section: string | null }
}
