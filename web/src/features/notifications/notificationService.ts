import { supabase } from '@/supabase/client'
import type { Notification } from './notificationTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const notificationService = {
  async getAll(page = 1) {
    const { data, error, count } = await supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (error) throw error
    return { data: data as Notification[], total: count ?? 0 }
  },

  async markAsRead(id: string) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
    if (error) throw error
  },

  async markAllAsRead() {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('is_read', false)
    if (error) throw error
  },
}
