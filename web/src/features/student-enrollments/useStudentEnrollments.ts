import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { studentEnrollmentService } from './studentEnrollmentService'
import type { StudentEnrollment } from './studentEnrollmentTypes'

export function useStudentEnrollments(page: number, search: string) {
  return useQuery({
    queryKey: ['studentEnrollments', page, search],
    queryFn: () => studentEnrollmentService.getAll(page, search),
  })
}

export function useStudentEnrollment(id: string) {
  return useQuery({
    queryKey: ['studentEnrollments', id],
    queryFn: () => studentEnrollmentService.getById(id),
    enabled: !!id,
  })
}

export function useCreateStudentEnrollment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: studentEnrollmentService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['studentEnrollments'] })
    },
  })
}

export function useUpdateEnrollmentStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: StudentEnrollment['status'] }) =>
      studentEnrollmentService.updateStatus(id, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['studentEnrollments'] })
    },
  })
}

export function useDeleteStudentEnrollment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: studentEnrollmentService.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['studentEnrollments'] })
    },
  })
}
