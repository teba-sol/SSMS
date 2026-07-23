import { useQuery } from '@tanstack/react-query'
import { attendanceService } from './attendanceService'

interface AttendanceFilters {
  classId?: string
  date?: string
  status?: string
}

export function useAttendance(page: number, filters?: AttendanceFilters) {
  return useQuery({
    queryKey: ['attendance', page, filters],
    queryFn: () => attendanceService.getAll(page, filters),
  })
}

export function useAttendanceByClassAndDate(classId: string, date: string) {
  return useQuery({
    queryKey: ['attendance', classId, date],
    queryFn: () => attendanceService.getByClassAndDate(classId, date),
    enabled: !!classId && !!date,
  })
}
