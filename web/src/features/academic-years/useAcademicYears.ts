import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { academicYearService } from './academicYearsService'

export function useAcademicYears(page: number = 1, search: string = '') {
  return useQuery({
    queryKey: ['academicYears', page, search],
    queryFn: () => academicYearService.getAll(page, search),
    placeholderData: (prev) => prev,
  })
}

export function useAcademicYear(id: string) {
  return useQuery({
    queryKey: ['academicYear', id],
    queryFn: () => academicYearService.getById(id),
    enabled: !!id,
  })
}

export function useAllAcademicYears() {
  return useQuery({
    queryKey: ['academicYears', 'all'],
    queryFn: () => academicYearService.getAllNoPagination(),
  })
}

export function useCreateAcademicYear() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: academicYearService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['academicYears'] })
    },
  })
}

export function useUpdateAcademicYear() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: { name?: string; start_date?: string; end_date?: string } }) =>
      academicYearService.update(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['academicYears'] })
    },
  })
}

export function useSetCurrentAcademicYear() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => academicYearService.setCurrent(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['academicYears'] })
    },
  })
}

export function useDeleteAcademicYear() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => academicYearService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['academicYears'] })
    },
  })
}
