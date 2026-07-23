export interface Teacher {
  id: string
  profile_id: string
  employee_id: string
  department: string | null
  qualification: string | null
  hire_date: string | null
  is_active: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface TeacherWithProfile extends Teacher {
  profiles?: {
    id: string
    first_name: string
    last_name: string
    email: string
    phone: string | null
    avatar_url: string | null
    is_active: boolean
  }
}
