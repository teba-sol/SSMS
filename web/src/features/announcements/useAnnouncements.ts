import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { announcementService } from './announcementService'

export function useAnnouncements(page: number, search: string) {
  return useQuery({
    queryKey: ['announcements', page, search],
    queryFn: () => announcementService.getAll(page, search),
  })
}

export function useAnnouncement(id: string) {
  return useQuery({
    queryKey: ['announcements', id],
    queryFn: () => announcementService.getById(id),
    enabled: !!id,
  })
}

export function useDeleteAnnouncement() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => announcementService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['announcements'] })
    },
  })
}

export function useTogglePublished() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, isPublished }: { id: string; isPublished: boolean }) =>
      announcementService.togglePublished(id, isPublished),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['announcements'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
    },
  })
}
