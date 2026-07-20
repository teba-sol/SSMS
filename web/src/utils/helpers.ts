import { clsx, type ClassValue } from 'clsx'

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs)
}

export function getInitials(firstName: string, lastName: string) {
  return `${firstName[0] ?? ''}${lastName[0] ?? ''}`.toUpperCase()
}

export function getFullName(first: string, last: string) {
  return `${first} ${last}`
}

export function truncate(str: string, max: number) {
  return str.length > max ? str.slice(0, max) + '...' : str
}
