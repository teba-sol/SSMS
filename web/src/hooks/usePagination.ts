import { useState, useCallback } from 'react'
import { ITEMS_PER_PAGE } from '@/utils/constants'

interface UsePaginationOptions {
  initialPage?: number
  initialPerPage?: number
}

export function usePagination({ initialPage = 1, initialPerPage = ITEMS_PER_PAGE }: UsePaginationOptions = {}) {
  const [page, setPage] = useState(initialPage)
  const [perPage, setPerPage] = useState(initialPerPage)

  const goToPage = useCallback((p: number) => setPage(p), [])
  const nextPage = useCallback(() => setPage((p) => p + 1), [])
  const prevPage = useCallback(() => setPage((p) => Math.max(1, p - 1)), [])
  const resetPage = useCallback(() => setPage(1), [])

  const offset = (page - 1) * perPage

  return { page, perPage, offset, setPage: goToPage, setPerPage, nextPage, prevPage, resetPage }
}
