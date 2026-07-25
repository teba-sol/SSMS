import { supabase } from '@/supabase/client'
import type { ActivityWithRelations } from './activityTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const activityService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('activities')
      .select(
        '*, organizer:profiles!organizer_id(id, first_name, last_name), classes(id, name, grade_level, section), academic_years(id, name, is_current)',
        { count: 'exact' },
      )
      .order('activity_date', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`title.ilike.%${search}%,activity_type.ilike.%${search}%,location.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as ActivityWithRelations[], total: count ?? 0 }
  },

  async create(data: {
    title: string
    description?: string
    activity_type: string
    activity_date: string
    location?: string
    class_id?: string
    academic_year_id: string
    created_by?: string
  }) {
    const { data: created, error } = await supabase
      .from('activities')
      .insert(data)
      .select()
      .single()
    if (error) throw error
    return created
  },

  async delete(id: string) {
    const { error } = await supabase.from('activities').delete().eq('id', id)
    if (error) throw error
  },
}
