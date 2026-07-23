import { useQuery } from '@tanstack/react-query'
import { parentService } from './parentService'

export function useParents(page: number, search: string) {
  return useQuery({
    queryKey: ['parents', page, search],
    queryFn: () => parentService.getAll(page, search),
  })
}

export function useParent(id: string) {
  return useQuery({
    queryKey: ['parents', id],
    queryFn: () => parentService.getById(id),
    enabled: !!id,
  })
}

export function useParentChildren(parentId: string) {
  return useQuery({
    queryKey: ['parents', parentId, 'children'],
    queryFn: () => parentService.getChildren(parentId),
    enabled: !!parentId,
  })
}
