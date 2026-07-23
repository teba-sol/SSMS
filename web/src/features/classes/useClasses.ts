import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { classService } from './classService'

export function useClasses(page: number, search: string) {
  return useQuery({
    queryKey: ['classes', page, search],
    queryFn: () => classService.getAll(page, search),
  })
}

export function useClass(id: string) {
  return useQuery({
    queryKey: ['classes', id],
    queryFn: () => classService.getById(id),
    enabled: !!id,
  })
}

export function useClassDetail(id: string) {
  return useQuery({
    queryKey: ['classes', id, 'detail'],
    queryFn: async () => {
      const [schoolClass, studentCount, enrolledStudents, classTeacher, subjects, attendanceSummary] =
        await Promise.all([
          classService.getById(id),
          classService.getStudentCount(id),
          classService.getEnrolledStudents(id),
          classService.getClassTeacher(id),
          classService.getSubjectsForClass(id),
          classService.getAttendanceSummary(id, new Date().toISOString().slice(0, 10)),
        ])
      return { schoolClass, studentCount, enrolledStudents, classTeacher, subjects, attendanceSummary }
    },
    enabled: !!id,
  })
}

export function useClassesByYear(academicYearId: string) {
  return useQuery({
    queryKey: ['classes', 'byYear', academicYearId],
    queryFn: () => classService.getByAcademicYear(academicYearId),
    enabled: !!academicYearId,
  })
}

export function useCreateClass() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: classService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['classes'] })
    },
  })
}

export function useUpdateClass() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<any> }) =>
      classService.update(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['classes'] })
    },
  })
}

export function useToggleClassActive() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, isActive }: { id: string; isActive: boolean }) =>
      classService.toggleActive(id, isActive),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['classes'] })
    },
  })
}
