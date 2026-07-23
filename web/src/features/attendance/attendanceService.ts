import { supabase } from '@/supabase/client'
import type { AttendanceWithRelations } from './attendanceTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const attendanceService = {
  async getByClassAndDate(classId: string, date: string) {
    const { data, error } = await supabase
      .from('attendance')
      .select('*, students(first_name, last_name, student_id)')
      .eq('class_id', classId)
      .eq('date', date)
    if (error) throw error
    return data as AttendanceWithRelations[]
  },

  async getAll(page = 1, filters?: { classId?: string; date?: string; status?: string }) {
    let query = supabase
      .from('attendance')
      .select('*, students(first_name, last_name, student_id), classes(name, grade_level, section)', { count: 'exact' })
      .order('date', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (filters?.classId) query = query.eq('class_id', filters.classId)
    if (filters?.date) query = query.eq('date', filters.date)
    if (filters?.status) query = query.eq('status', filters.status)

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as AttendanceWithRelations[], total: count ?? 0 }
  },

  async upsert(records: { student_id: string; class_id: string; date: string; status: string; marked_by: string; notes?: string }[]) {
    const { data, error } = await supabase
      .from('attendance')
      .upsert(records, { onConflict: 'student_id,class_id,date' })
      .select()
    if (error) throw error
    return data
  },
}
