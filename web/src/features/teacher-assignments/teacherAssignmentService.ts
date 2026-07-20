import { supabase } from '@/supabase/client'
import type { TeacherAssignment, TeacherAssignmentWithRelations } from './teacherAssignmentTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const teacherAssignmentService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('teacher_assignments')
      .select(
        '*, teachers(id, employee_id, profiles!profile_id(id, first_name, last_name, email)), classes(id, name, grade_level, section), subjects(id, name, code), academic_years(id, name, is_current)',
        { count: 'exact' },
      )
      .order('created_at', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(
        `teachers.profiles.first_name.ilike.%${search}%,teachers.profiles.last_name.ilike.%${search}%,classes.name.ilike.%${search}%,subjects.name.ilike.%${search}%`,
      )
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as TeacherAssignmentWithRelations[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select(
        '*, teachers(id, employee_id, profiles!profile_id(id, first_name, last_name, email)), classes(id, name, grade_level, section), subjects(id, name, code), academic_years(id, name, is_current)',
      )
      .eq('id', id)
      .single()
    if (error) throw error
    return data as TeacherAssignmentWithRelations
  },

  async create(data: Pick<TeacherAssignment, 'teacher_id' | 'class_id' | 'subject_id' | 'academic_year_id' | 'created_by'>) {
    const { data: created, error } = await supabase
      .from('teacher_assignments')
      .insert(data)
      .select()
      .single()
    if (error) throw error
    return created as TeacherAssignment
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('teacher_assignments')
      .delete()
      .eq('id', id)
    if (error) throw error
  },
}
