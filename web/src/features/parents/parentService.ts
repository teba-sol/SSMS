import { supabase } from '@/supabase/client'
import type { ParentWithStudents, ParentStudent } from './parentTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const parentService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('profiles')
      .select('*, parent_students!parent_students_parent_id_fkey(*, students(id, first_name, last_name, student_id))', { count: 'exact' })
      .eq('role', 'parent')
      .order('last_name')
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`first_name.ilike.%${search}%,last_name.ilike.%${search}%,email.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: (data ?? []) as ParentWithStudents[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as ParentWithStudents
  },

  async update(id: string, updates: { first_name?: string; last_name?: string; phone?: string }) {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async toggleActive(id: string, isActive: boolean) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ is_active: isActive })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getChildren(parentId: string) {
    const { data, error } = await supabase
      .from('parent_students')
      .select('*, students(id, first_name, last_name, student_id)')
      .eq('parent_id', parentId)
      .eq('is_active', true)
    if (error) throw error
    return data as (ParentStudent & { students: { id: string; first_name: string; last_name: string; student_id: string } | null })[]
  },

  async linkStudent(parentId: string, studentId: string, relationship: string) {
    const { data, error } = await supabase
      .from('parent_students')
      .insert({
        parent_id: parentId,
        student_id: studentId,
        relationship,
        is_primary: false,
        is_active: true,
      })
      .select()
      .single()
    if (error) throw error
    return data as ParentStudent
  },

  async unlinkStudent(id: string) {
    const { error } = await supabase
      .from('parent_students')
      .update({ is_active: false })
      .eq('id', id)
    if (error) throw error
  },

  async searchStudents(search: string) {
    let query = supabase
      .from('students')
      .select('id, first_name, last_name, student_id')
      .order('last_name')
      .limit(20)

    if (search) {
      query = query.or(`first_name.ilike.%${search}%,last_name.ilike.%${search}%,student_id.ilike.%${search}%`)
    }

    const { data, error } = await query
    if (error) throw error
    return data as { id: string; first_name: string; last_name: string; student_id: string }[]
  },
}
