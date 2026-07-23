import { useState, useEffect, useCallback } from 'react'
import { supabase } from '@/supabase/client'

interface UseSupabaseQueryOptions<T> {
  fetcher: () => Promise<T>
  deps?: unknown[]
}

export function useSupabaseQuery<T>({ fetcher, deps = [] }: UseSupabaseQueryOptions<T>) {
  const [data, setData] = useState<T | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const refetch = useCallback(async () => {
    setIsLoading(true)
    setError(null)
    try {
      const result = await fetcher()
      setData(result)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setIsLoading(false)
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)

  useEffect(() => {
    refetch()
  }, [refetch])

  return { data, isLoading, error, refetch }
}

export { supabase }
