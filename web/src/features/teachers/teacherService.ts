import { supabase } from '@/supabase/client'
import type { TeacherWithProfile } from './teacherTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const teacherService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('teachers')
      .select('*, profiles!profile_id(id, first_name, last_name, email, phone, avatar_url, is_active)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`employee_id.ilike.%${search}%,department.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as TeacherWithProfile[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('teachers')
      .select('*, profiles!profile_id(id, first_name, last_name, email, phone, avatar_url, is_active)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as TeacherWithProfile
  },

  async update(id: string, updates: Partial<TeacherWithProfile>) {
    const { profiles, ...teacherUpdates } = updates
    const { data, error } = await supabase
      .from('teachers')
      .update(teacherUpdates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as TeacherWithProfile
  },

  async toggleActive(id: string, isActive: boolean) {
    const { data, error } = await supabase
      .from('teachers')
      .update({ is_active: isActive })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getAssignments(teacherId: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select(`
        id,
        classes(id, name, grade_level, section),
        subjects(id, name, code),
        academic_years(id, name, is_current)
      `)
      .eq('teacher_id', teacherId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return (data as any[]).map((row) => ({
      id: row.id as string,
      classes: Array.isArray(row.classes) ? row.classes[0] as { id: string; name: string; grade_level: number; section: string | null } | undefined : row.classes as { id: string; name: string; grade_level: number; section: string | null } | undefined,
      subjects: Array.isArray(row.subjects) ? row.subjects[0] as { id: string; name: string; code: string } | undefined : row.subjects as { id: string; name: string; code: string } | undefined,
      academic_years: Array.isArray(row.academic_years) ? row.academic_years[0] as { id: string; name: string; is_current: boolean } | undefined : row.academic_years as { id: string; name: string; is_current: boolean } | undefined,
    }))
  },

  async getStats(teacherId: string) {
    const assignments = await this.getAssignments(teacherId)
    const subjectIds = new Set<string>()
    const classIds = new Set<string>()
    for (const a of assignments) {
      if (a.subjects) subjectIds.add(a.subjects.id)
      if (a.classes) classIds.add(a.classes.id)
    }

    let totalStudents = 0
    if (classIds.size > 0) {
      const { count } = await supabase
        .from('student_enrollments')
        .select('*', { count: 'exact', head: true })
        .in('class_id', Array.from(classIds))
        .eq('status', 'active')
      totalStudents = count ?? 0
    }

    return {
      subjectsCount: subjectIds.size,
      classesCount: classIds.size,
      studentsCount: totalStudents,
    }
  },
}
