export type UserRole = 'administrator' | 'teacher' | 'parent'

export interface Profile {
  id: string
  email: string
  first_name: string
  last_name: string
  phone: string | null
  avatar_url: string | null
  role: UserRole
  is_active: boolean
  email_verified: boolean
  last_login: string | null
  created_at: string
  updated_at: string
}

export interface AuthUser {
  id: string
  email: string
}

export interface AuthState {
  user: AuthUser | null
  profile: Profile | null
  isLoading: boolean
  isAuthenticated: boolean
}
