import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { activityService } from './activityService'

export function useActivities(page: number, search: string) {
  return useQuery({
    queryKey: ['activities', page, search],
    queryFn: () => activityService.getAll(page, search),
  })
}

export function useCreateActivity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: activityService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['activities'] })
    },
  })
}

export function useDeleteActivity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: activityService.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['activities'] })
    },
  })
}
