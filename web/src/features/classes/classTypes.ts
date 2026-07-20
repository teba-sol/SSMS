export interface SchoolClass {
  id: string
  academic_year_id: string
  name: string
  grade_level: number
  section: string | null
  capacity: number
  room: string | null
  is_active: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface SchoolClassWithYear extends SchoolClass {
  academic_years: {
    id: string
    name: string
    is_current: boolean
  }
}
