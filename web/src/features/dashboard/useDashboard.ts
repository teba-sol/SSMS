import { useQuery } from '@tanstack/react-query'
import { dashboardService } from './dashboardService'

export function useDashboard() {
  return useQuery({
    queryKey: ['dashboard'],
    queryFn: () => dashboardService.getStats(),
  })
}
