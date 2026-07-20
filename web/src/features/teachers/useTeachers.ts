import { useQuery } from '@tanstack/react-query'
import { teacherService } from './teacherService'

export function useTeachers(page: number, search: string) {
  return useQuery({
    queryKey: ['teachers', page, search],
    queryFn: () => teacherService.getAll(page, search),
  })
}

export function useTeacher(id: string) {
  return useQuery({
    queryKey: ['teachers', id],
    queryFn: () => teacherService.getById(id),
    enabled: !!id,
  })
}

export function useTeacherDetail(id: string) {
  return useQuery({
    queryKey: ['teachers', id, 'detail'],
    queryFn: async () => {
      const [teacher, assignments, stats] = await Promise.all([
        teacherService.getById(id),
        teacherService.getAssignments(id),
        teacherService.getStats(id),
      ])
      return { teacher, assignments, stats }
    },
    enabled: !!id,
  })
}
