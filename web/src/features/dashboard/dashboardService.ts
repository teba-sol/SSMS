import { supabase } from '@/supabase/client'
import type { DashboardStats } from './dashboardTypes'

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const today = new Date().toISOString().split('T')[0]

    const [students, teachers, classes, parents, enrollments, academicYear, announcements, attPresent, attAbsent, attLate, attExcused, activities] =
      await Promise.all([
        supabase.from('students').select('id', { count: 'exact', head: true }),
        supabase.from('teachers').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('classes').select('id', { count: 'exact', head: true }).eq('is_active', true),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'parent'),
        supabase.from('student_enrollments').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('academic_years').select('id, year_name').eq('is_current', true).maybeSingle(),
        supabase
          .from('announcements')
          .select('id, title, priority, created_at')
          .eq('is_published', true)
          .order('created_at', { ascending: false })
          .limit(5),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'present'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'absent'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'late'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('date', today).eq('status', 'excused'),
        supabase
          .from('activities')
          .select('id, title, activity_type, activity_date')
          .order('activity_date', { ascending: false })
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
      todayAttendance: {
        present: attPresent.count ?? 0,
        absent: attAbsent.count ?? 0,
        late: attLate.count ?? 0,
        excused: attExcused.count ?? 0,
      },
      recentActivities: activities.data ?? [],
    }
  },
}
