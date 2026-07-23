export interface StudentEnrollment {
  id: string
  student_id: string
  class_id: string
  enrollment_date: string
  status: 'active' | 'transferred' | 'withdrawn' | 'graduated'
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface StudentEnrollmentWithRelations extends StudentEnrollment {
  students: { id: string; first_name: string; last_name: string; student_id: string }
  classes: { id: string; name: string; grade_level: number; section: string | null }
}
