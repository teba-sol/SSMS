import type { Profile } from '@/types'

export interface ParentStudent {
  id: string
  parent_id: string
  student_id: string
  relationship: 'father' | 'mother' | 'guardian' | 'other'
  is_primary: boolean
  is_active: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface ParentWithStudents extends Profile {
  parent_students?: (ParentStudent & {
    students?: { id: string; first_name: string; last_name: string; student_id: string }
  })[]
}
