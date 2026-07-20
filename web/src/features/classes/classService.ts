import { supabase } from '@/supabase/client'
import type { SchoolClass, SchoolClassWithYear } from './classTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const classService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('classes')
      .select('*, academic_years(id, name, is_current)', { count: 'exact' })
      .order('grade_level', { ascending: true })
      .order('section', { ascending: true })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`name.ilike.%${search}%,room.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as SchoolClassWithYear[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('classes')
      .select('*, academic_years(id, name, is_current)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as SchoolClassWithYear
  },

  async getByAcademicYear(academicYearId: string) {
    const { data, error } = await supabase
      .from('classes')
      .select('*')
      .eq('academic_year_id', academicYearId)
      .order('grade_level', { ascending: true })
      .order('section', { ascending: true })
    if (error) throw error
    return data as SchoolClass[]
  },

  async create(classData: Omit<SchoolClass, 'id' | 'created_at' | 'updated_at'>) {
    const { data, error } = await supabase
      .from('classes')
      .insert(classData)
      .select()
      .single()
    if (error) throw error
    return data as SchoolClass
  },

  async update(id: string, updates: Partial<SchoolClass>) {
    const { academic_years, ...classUpdates } = updates as any
    const { data, error } = await supabase
      .from('classes')
      .update(classUpdates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as SchoolClass
  },

  async toggleActive(id: string, isActive: boolean) {
    const { data, error } = await supabase
      .from('classes')
      .update({ is_active: isActive })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getStudentCount(classId: string) {
    const { count, error } = await supabase
      .from('student_enrollments')
      .select('*', { count: 'exact', head: true })
      .eq('class_id', classId)
      .eq('status', 'active')
    if (error) throw error
    return count ?? 0
  },

  async getEnrolledStudents(classId: string) {
    const { data, error } = await supabase
      .from('student_enrollments')
      .select('id, enrollment_date, status, students(id, first_name, last_name, student_id, date_of_birth, gender)')
      .eq('class_id', classId)
      .eq('status', 'active')
      .order('students(last_name)', { ascending: true })
    if (error) throw error
    return (data as any[]).map((row) => ({
      id: row.id as string,
      enrollment_date: row.enrollment_date as string,
      status: row.status as string,
      students: row.students?.[0] as { id: string; first_name: string; last_name: string; student_id: string; date_of_birth: string | null; gender: string | null } | null,
    }))
  },

  async getClassTeacher(classId: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select('teachers(id, employee_id, profiles!profile_id(first_name, last_name))')
      .eq('class_id', classId)
      .limit(1)
      .maybeSingle()
    if (error) throw error
    const t = data?.teachers as any
    if (!t) return null
    const p = t.profiles?.[0] ?? t.profiles
    return p ? { id: t.id as string, name: `${p.first_name} ${p.last_name}` } : null
  },

  async getSubjectsForClass(classId: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select('subjects(id, name, code)')
      .eq('class_id', classId)
    if (error) throw error
    const seen = new Set<string>()
    const subjects = (data as any[])
      .map((r) => {
        const s = Array.isArray(r.subjects) ? r.subjects[0] : r.subjects
        return s as { id: string; name: string; code: string } | null
      })
      .filter((s) => {
        if (!s || seen.has(s.id)) return false
        seen.add(s.id)
        return true
      })
    return subjects as { id: string; name: string; code: string }[]
  },

  async getAttendanceSummary(classId: string, date: string) {
    const { data, error } = await supabase
      .from('attendance')
      .select('status')
      .eq('class_id', classId)
      .eq('date', date)
    if (error) throw error
    const summary = { present: 0, absent: 0, late: 0, excused: 0, total: 0 }
    for (const row of data as { status: string }[]) {
      if (row.status in summary) {
        ;(summary as any)[row.status]++
        summary.total++
      }
    }
    return summary
  },
}
