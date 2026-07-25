export interface Notification {
  id: string
  user_id: string
  title: string
  body: string
  type: string
  reference_type: string | null
  reference_id: string | null
  action_url: string | null
  is_read: boolean
  created_at: string
}
