export interface Announcement {
  id: string
  title: string
  content: string
  author_id: string
  target_audience: 'all' | 'teachers' | 'parents'
  class_id: string | null
  priority: 'low' | 'normal' | 'high' | 'urgent'
  is_published: boolean
  created_at: string
  updated_at: string
}

export interface AnnouncementWithAuthor extends Announcement {
  profiles: { first_name: string; last_name: string }
}
