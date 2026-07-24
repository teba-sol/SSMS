export interface DashboardStats {
  totalStudents: number
  totalTeachers: number
  totalClasses: number
  totalParents: number
  totalEnrollments: number
  currentAcademicYear: { id: string; year_name: string } | null
  recentAnnouncements: { id: string; title: string; priority: string; created_at: string }[]
  todayAttendance: { present: number; absent: number; late: number; excused: number }
  recentActivities: { id: string; title: string; activity_type: string; activity_date: string }[]
}
