export interface AcademicYear {
  id: string
  name: string
  start_date: string
  end_date: string
  is_current: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface AcademicYearWithProfile extends AcademicYear {
  profiles: {
    id: string
    first_name: string
    last_name: string
    email: string
    phone: string | null
    avatar_url: string | null
    is_active: boolean
  }
}
