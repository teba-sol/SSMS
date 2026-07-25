import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { notificationService } from './notificationService'

export function useNotifications(page: number) {
  return useQuery({
    queryKey: ['notifications', page],
    queryFn: () => notificationService.getAll(page),
  })
}

export function useMarkAllNotificationsRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: notificationService.markAllAsRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })
}
