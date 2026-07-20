export interface TeacherAssignment {
  id: string
  teacher_id: string
  class_id: string
  subject_id: string
  academic_year_id: string
  created_by: string | null
  created_at: string
}

export interface TeacherAssignmentWithRelations extends TeacherAssignment {
  teachers: {
    id: string
    employee_id: string
    profiles: { first_name: string; last_name: string; email: string }
  }
  classes: { id: string; name: string; grade_level: number; section: string | null }
  subjects: { id: string; name: string; code: string }
  academic_years: { id: string; name: string; is_current: boolean }
}
