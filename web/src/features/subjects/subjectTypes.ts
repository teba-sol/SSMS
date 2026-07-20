export interface Subject {
  id: string
  name: string
  code: string
  description: string | null
  is_active: boolean
  created_by: string | null
  created_at: string
}
