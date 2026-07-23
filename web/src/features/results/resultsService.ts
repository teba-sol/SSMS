import { supabase } from '@/supabase/client'
import type { ResultWithRelations } from './resultsTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const resultsService = {
  async getAll(page = 1, filters?: { classId?: string; examType?: string; studentId?: string }) {
    let query = supabase
      .from('results')
      .select('*, students(first_name, last_name, student_id), teacher_assignments(classes(name, grade_level), subjects(name, code))', { count: 'exact' })
      .order('exam_date', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (filters?.examType) query = query.eq('exam_type', filters.examType)
    if (filters?.studentId) query = query.eq('student_id', filters.studentId)

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as ResultWithRelations[], total: count ?? 0 }
  },

  async getByStudent(studentId: string) {
    const { data, error } = await supabase
      .from('results')
      .select('*, teacher_assignments(classes(name, grade_level), subjects(name, code))')
      .eq('student_id', studentId)
      .order('exam_date', { ascending: false })
    if (error) throw error
    return data as ResultWithRelations[]
  },

  async create(result: Omit<ResultWithRelations, 'id' | 'created_at' | 'updated_at' | 'students' | 'teacher_assignments'>) {
    const { data, error } = await supabase
      .from('results')
      .insert(result)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<ResultWithRelations>) {
    const { data, error } = await supabase
      .from('results')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id: string) {
    const { error } = await supabase.from('results').delete().eq('id', id)
    if (error) throw error
  },
}
