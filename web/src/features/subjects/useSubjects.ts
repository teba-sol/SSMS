import { useQuery } from '@tanstack/react-query'
import { subjectService } from './subjectService'

export function useSubjects(page: number, search: string) {
  return useQuery({
    queryKey: ['subjects', page, search],
    queryFn: () => subjectService.getAll(page, search),
  })
}

export function useSubject(id: string) {
  return useQuery({
    queryKey: ['subjects', id],
    queryFn: () => subjectService.getById(id),
    enabled: !!id,
  })
}

export function useSubjectDetail(id: string) {
  return useQuery({
    queryKey: ['subjects', id, 'detail'],
    queryFn: async () => {
      const [subject, teachers, classes] = await Promise.all([
        subjectService.getById(id),
        subjectService.getTeachersForSubject(id),
        subjectService.getClassesForSubject(id),
      ])
      return { subject, teachers, classes }
    },
    enabled: !!id,
  })
}

export function useAllActiveSubjects() {
  return useQuery({
    queryKey: ['subjects', 'active'],
    queryFn: () => subjectService.getAllActive(),
  })
}
