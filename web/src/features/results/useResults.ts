import { useQuery } from '@tanstack/react-query'
import { resultsService } from './resultsService'

interface ResultsFilters {
  classId?: string
  examType?: string
  studentId?: string
}

export function useResults(page: number, filters?: ResultsFilters) {
  return useQuery({
    queryKey: ['results', page, filters],
    queryFn: () => resultsService.getAll(page, filters),
  })
}

export function useStudentResults(studentId: string) {
  return useQuery({
    queryKey: ['results', 'student', studentId],
    queryFn: () => resultsService.getByStudent(studentId),
    enabled: !!studentId,
  })
}
