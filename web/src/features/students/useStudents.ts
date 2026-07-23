import { useQuery } from '@tanstack/react-query'
import { studentService } from './studentService'

export function useStudents(page: number, search: string) {
  return useQuery({
    queryKey: ['students', page, search],
    queryFn: () => studentService.getAll(page, search),
  })
}

export function useStudent(id: string) {
  return useQuery({
    queryKey: ['students', id],
    queryFn: () => studentService.getById(id),
    enabled: !!id,
  })
}
