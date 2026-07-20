export interface Result {
  id: string
  student_id: string
  teacher_assignment_id: string
  marks_obtained: number | null
  total_marks: number | null
  grade: string | null
  exam_type: 'midterm' | 'final' | 'quiz' | 'assignment' | 'project'
  exam_date: string
  remarks: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface ResultWithRelations extends Result {
  students?: { first_name: string; last_name: string; student_id: string }
  teacher_assignments?: {
    classes?: { name: string; grade_level: number }
    subjects?: { name: string; code: string }
  }
}
