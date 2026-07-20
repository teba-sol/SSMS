import { supabase } from '@/supabase/client'
import type { DashboardStats } from './dashboardTypes'

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const [students, teachers, classes, parents, enrollments, academicYear, announcements] =
      await Promise.all([
        supabase.from('students').select('id', { count: 'exact', head: true }),
        supabase.from('teachers').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('classes').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'parent'),
        supabase.from('student_enrollments').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('academic_years').select('id, name').eq('is_current', true).maybeSingle(),
        supabase
          .from('announcements')
          .select('id, title, priority, created_at')
          .eq('is_published', true)
          .order('created_at', { ascending: false })
          .limit(5),
      ])

    return {
      totalStudents: students.count ?? 0,
      totalTeachers: teachers.count ?? 0,
      totalClasses: classes.count ?? 0,
      totalParents: parents.count ?? 0,
      totalEnrollments: enrollments.count ?? 0,
      currentAcademicYear: academicYear.data,
      recentAnnouncements: announcements.data ?? [],
    }
  },
}
