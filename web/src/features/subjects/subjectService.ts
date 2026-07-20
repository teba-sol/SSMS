import { supabase } from '@/supabase/client'
import type { Subject } from './subjectTypes'
import { ITEMS_PER_PAGE } from '@/utils/constants'

export const subjectService = {
  async getAll(page = 1, search = '') {
    let query = supabase
      .from('subjects')
      .select('*', { count: 'exact' })
      .order('name', { ascending: true })
      .range((page - 1) * ITEMS_PER_PAGE, page * ITEMS_PER_PAGE - 1)

    if (search) {
      query = query.or(`name.ilike.%${search}%,code.ilike.%${search}%`)
    }

    const { data, error, count } = await query
    if (error) throw error
    return { data: data as Subject[], total: count ?? 0 }
  },

  async getById(id: string) {
    const { data, error } = await supabase
      .from('subjects')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Subject
  },

  async getAllActive() {
    const { data, error } = await supabase
      .from('subjects')
      .select('*')
      .eq('is_active', true)
      .order('name', { ascending: true })
    if (error) throw error
    return data as Subject[]
  },

  async create(data: Pick<Subject, 'name' | 'code' | 'description'>) {
    const { data: created, error } = await supabase
      .from('subjects')
      .insert(data)
      .select()
      .single()
    if (error) throw error
    return created as Subject
  },

  async update(id: string, updates: Partial<Pick<Subject, 'name' | 'code' | 'description' | 'is_active'>>) {
    const { data, error } = await supabase
      .from('subjects')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Subject
  },

  async toggleActive(id: string, isActive: boolean) {
    const { data, error } = await supabase
      .from('subjects')
      .update({ is_active: isActive })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async getTeachersForSubject(subjectId: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select('teachers(id, employee_id, profiles!profile_id(id, first_name, last_name, email))')
      .eq('subject_id', subjectId)
    if (error) throw error
    const seen = new Set<string>()
    const teachers = (data as any[])
      .map((r) => {
        const t = Array.isArray(r.teachers) ? r.teachers[0] : r.teachers
        if (!t) return null
        const p = Array.isArray(t.profiles) ? t.profiles[0] : t.profiles
        return {
          id: t.id as string,
          employee_id: t.employee_id as string,
          name: p ? `${p.first_name} ${p.last_name}` : '-',
          email: p?.email ?? '-',
        }
      })
      .filter((t) => {
        if (!t || seen.has(t.id)) return false
        seen.add(t.id)
        return true
      })
    return teachers as { id: string; employee_id: string; name: string; email: string }[]
  },

  async getClassesForSubject(subjectId: string) {
    const { data, error } = await supabase
      .from('teacher_assignments')
      .select('classes(id, name, grade_level, section)')
      .eq('subject_id', subjectId)
    if (error) throw error
    const seen = new Set<string>()
    const classes = (data as any[])
      .map((r) => {
        const c = Array.isArray(r.classes) ? r.classes[0] : r.classes
        return c as { id: string; name: string; grade_level: number; section: string | null } | null
      })
      .filter((c) => {
        if (!c || seen.has(c.id)) return false
        seen.add(c.id)
        return true
      })
    return classes as { id: string; name: string; grade_level: number; section: string | null }[]
  },
}
