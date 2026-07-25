export interface Activity {
  id: string
  title: string
  description: string | null
  activity_type: string
  activity_date: string
  location: string | null
  organizer_id: string | null
  class_id: string | null
  academic_year_id: string
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface ActivityWithRelations extends Activity {
  organizer?: { id: string; first_name: string; last_name: string } | null
  classes?: { id: string; name: string; grade_level: number; section: string | null } | null
  academic_years?: { id: string; name: string; is_current: boolean } | null
}
