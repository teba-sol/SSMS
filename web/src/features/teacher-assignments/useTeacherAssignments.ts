import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { teacherAssignmentService } from './teacherAssignmentService'

export function useTeacherAssignments(page: number, search: string) {
  return useQuery({
    queryKey: ['teacherAssignments', page, search],
    queryFn: () => teacherAssignmentService.getAll(page, search),
  })
}

export function useTeacherAssignment(id: string) {
  return useQuery({
    queryKey: ['teacherAssignments', id],
    queryFn: () => teacherAssignmentService.getById(id),
    enabled: !!id,
  })
}

export function useCreateTeacherAssignment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: teacherAssignmentService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teacherAssignments'] })
    },
  })
}

export function useDeleteTeacherAssignment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: teacherAssignmentService.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['teacherAssignments'] })
    },
  })
}
