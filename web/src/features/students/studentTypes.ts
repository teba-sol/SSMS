export interface Student {
  id: string
  student_id: string
  first_name: string
  middle_name: string | null
  last_name: string
  date_of_birth: string
  gender: 'male' | 'female' | 'other' | null
  address: string | null
  emergency_contact: string | null
  emergency_phone: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

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

export interface StudentWithEnrollment extends Student {
  enrollments?: StudentEnrollment & {
    classes?: { name: string; grade_level: number; section: string | null }
  }
}
