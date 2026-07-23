import { supabase } from '@/supabase/client'
import { ITEMS_PER_PAGE } from '@/utils/constants'
import type { AcademicYear } from './academicYearsTypes'

export const academicYearService = {
  async getAll(page: number = 1, search: string = '') {
    let query = supabase
      .from('academic_years')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })

    if (search) {
      query = query.ilike('name', `%${search}%`)
    }

    const { data, error, count } = await query
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (error) throw error
    return { data: data ?? [], total: count ?? 0 }
  },

  async getAllNoPagination() {
    const { data, error } = await supabase
      .from('academic_years')
      .select('*')
      .order('name', { ascending: false })

    if (error) throw error
    return data ?? []
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('academic_years')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(year: Omit<AcademicYear, 'id' | 'created_at' | 'updated_at'>) {
    const { data, error } = await supabase
      .from('academic_years')
      .insert(year)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Pick<AcademicYear, 'name' | 'start_date' | 'end_date'>>) {
    const { data, error } = await supabase
      .from('academic_years')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async setCurrent(id: string) {
    try {
      const { error } = await supabase.rpc('set_current_academic_year', {
        p_year_id: id,
      })
      if (error) throw error
    } catch {
      // Fallback: unset all current, then set this one
      // This bypasses the trigger by updating is_current directly
      await supabase
        .from('academic_years')
        .update({ is_current: false })
        .eq('is_current', true)

      const { error } = await supabase
        .from('academic_years')
        .update({ is_current: true })
        .eq('id', id)
      if (error) throw error
    }
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('academic_years')
      .delete()
      .eq('id', id)
    if (error) throw error
  },
}
