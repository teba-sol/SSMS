export interface DashboardStats {
  totalStudents: number
  totalTeachers: number
  totalClasses: number
  totalParents: number
  totalEnrollments: number
  currentAcademicYear: { id: string; name: string } | null
  recentAnnouncements: { id: string; title: string; priority: string; created_at: string }[]
}
