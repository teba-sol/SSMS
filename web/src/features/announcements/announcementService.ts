import { supabase } from '@/supabase/client'
import type { Announcement, AnnouncementWithAuthor } from './announcementTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const announcementService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('announcements')
      .select('*, profiles!author_id(first_name, last_name)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.ilike('title', `%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: (data ?? []) as AnnouncementWithAuthor[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('announcements')
      .select('*, profiles!author_id(first_name, last_name)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as AnnouncementWithAuthor
  },

  async create(data: Pick<Announcement, 'title' | 'content' | 'target_audience' | 'priority' | 'is_published' | 'class_id'>) {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    const { data: created, error } = await supabase
      .from('announcements')
      .insert({ ...data, author_id: user.id })
      .select()
      .single()
    if (error) throw error
    return created as Announcement
  },

  async update(id: string, updates: Partial<Pick<Announcement, 'title' | 'content' | 'target_audience' | 'priority' | 'is_published' | 'class_id'>>) {
    const { data, error } = await supabase
      .from('announcements')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Announcement
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('announcements')
      .delete()
      .eq('id', id)
    if (error) throw error
  },

  async togglePublished(id: string, isPublished: boolean) {
    const { data, error } = await supabase
      .from('announcements')
      .update({ is_published: isPublished, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Announcement
  },
}
