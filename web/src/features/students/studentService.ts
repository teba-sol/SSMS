import { supabase } from '@/supabase/client'
import type { Student } from './studentTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const studentService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('students')
      .select('*', { count: 'exact' })
      .order('last_name')
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`first_name.ilike.%${search}%,last_name.ilike.%${search}%,student_id.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as Student[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('students')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Student
  },

  async create(student: Omit<Student, 'id' | 'created_at' | 'updated_at'>) {
    const { data, error } = await supabase
      .from('students')
      .insert(student)
      .select()
      .single()
    if (error) throw error
    return data as Student
  },

  async update(id: string, updates: Partial<Student>) {
    const { data, error } = await supabase
      .from('students')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Student
  },

  async getByClass(classId: string) {
    const { data, error } = await supabase
      .from('student_enrollments')
      .select('*, students(*)')
      .eq('class_id', classId)
      .eq('status', 'active')
    if (error) throw error
    return data
  },
}
