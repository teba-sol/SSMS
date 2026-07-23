import { supabase } from '@/supabase/client'
import type { StudentEnrollment, StudentEnrollmentWithRelations } from './studentEnrollmentTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const studentEnrollmentService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('student_enrollments')
      .select(
        '*, students(id, first_name, last_name, student_id), classes(id, name, grade_level, section)',
        { count: 'exact' },
      )
      .order('created_at', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(
        `students.first_name.ilike.%${search}%,students.last_name.ilike.%${search}%,students.student_id.ilike.%${search}%,classes.name.ilike.%${search}%`,
      )
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as StudentEnrollmentWithRelations[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('student_enrollments')
      .select(
        '*, students(id, first_name, last_name, student_id), classes(id, name, grade_level, section)',
      )
      .eq('id', id)
      .single()
    if (error) throw error
    return data as StudentEnrollmentWithRelations
  },

  async create(data: Pick<StudentEnrollment, 'student_id' | 'class_id' | 'enrollment_date' | 'created_by'>) {
    const { data: created, error } = await supabase
      .from('student_enrollments')
      .insert(data)
      .select()
      .single()
    if (error) throw error
    return created as StudentEnrollment
  },

  async updateStatus(id: string, status: StudentEnrollment['status']) {
    const { data, error } = await supabase
      .from('student_enrollments')
      .update({ status })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as StudentEnrollment
  },

  async delete(id: string) {
    const { error } = await supabase
      .from('student_enrollments')
      .delete()
      .eq('id', id)
    if (error) throw error
  },
}
