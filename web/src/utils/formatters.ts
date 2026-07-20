export function formatDate(date: string | Date) {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(new Date(date))
}

export function formatDateTime(date: string | Date) {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(date))
}

export function formatPercent(value: number, total: number) {
  if (total === 0) return '0%'
  return `${Math.round((value / total) * 100)}%`
}

export function formatMarks(obtained: number | null, total: number | null) {
  if (obtained == null || total == null) return '-'
  return `${obtained}/${total}`
}

export function percentageLabel(status: string) {
  const labels: Record<string, string> = {
    present: 'Present',
    absent: 'Absent',
    late: 'Late',
    excused: 'Excused',
  }
  return labels[status] ?? status
}

export function enrollmentStatusLabel(status: string) {
  return status.charAt(0).toUpperCase() + status.slice(1)
}
