import { createContext, useContext, useState, useEffect, useCallback, useRef, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/supabase/client'
import type { Profile } from '@/types'

interface AuthContextValue {
  profile: Profile | null
  isLoading: boolean
  isAuthenticated: boolean
  signIn: (email: string, password: string) => Promise<{ error: string | null }>
  signOut: () => Promise<void>
  resetPassword: (email: string) => Promise<{ error: string | null }>
  refetchProfile: () => Promise<Profile | null>
}

const AuthContext = createContext<AuthContextValue | null>(null)

async function fetchProfileForUser(userId: string): Promise<Profile | null> {
  const fetch = async (): Promise<Profile | null> => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle()
      if (error || !data) return null
      return data
    } catch {
      return null
    }
  }
  return Promise.race([
    fetch(),
    new Promise<Profile | null>((resolve) => setTimeout(() => resolve(null), 10000)),
  ])
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<Profile | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const mountedRef = useRef(true)
  const resolvedRef = useRef(false)

  const resolve = useCallback(async (userId: string) => {
    if (resolvedRef.current) return
    resolvedRef.current = true
    const data = await fetchProfileForUser(userId)
    if (mountedRef.current) {
      setProfile(data)
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    mountedRef.current = true
    resolvedRef.current = false

    let cancelled = false

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (cancelled || !mountedRef.current) return

        if (event === 'SIGNED_OUT') {
          resolvedRef.current = true
          setProfile(null)
          setIsLoading(false)
          return
        }

        if ((event === 'INITIAL_SESSION' || event === 'SIGNED_IN') && session) {
          resolve(session.user.id)
          return
        }

        if (event === 'INITIAL_SESSION' && !session) {
          resolvedRef.current = true
          setProfile(null)
          setIsLoading(false)
          return
        }
      }
    )

    const safetyTimeout = setTimeout(() => {
      if (!cancelled && mountedRef.current && !resolvedRef.current) {
        supabase.auth.getSession().then(({ data: { session } }) => {
          if (cancelled || !mountedRef.current || resolvedRef.current) return
          if (session) {
            resolve(session.user.id)
          } else {
            resolvedRef.current = true
            setProfile(null)
            setIsLoading(false)
          }
        })
      }
    }, 3000)

    return () => {
      cancelled = true
      mountedRef.current = false
      clearTimeout(safetyTimeout)
      subscription.unsubscribe()
    }
  }, [resolve])

  const signIn = async (email: string, password: string) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error

      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', data.user.id)
        .maybeSingle()

      if (profileError) throw profileError
      if (!profileData) throw new Error('Profile not found. Please contact an administrator.')

      resolvedRef.current = true
      if (mountedRef.current) setProfile(profileData)
      return { error: null }
    } catch (error) {
      return { error: (error as Error).message }
    }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    resolvedRef.current = true
    if (mountedRef.current) {
      setProfile(null)
      setIsLoading(false)
    }
    navigate('/login')
  }

  const resetPassword = async (email: string) => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      })
      if (error) throw error
      return { error: null }
    } catch (error) {
      return { error: (error as Error).message }
    }
  }

  const refetchProfile = useCallback(async (): Promise<Profile | null> => {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) return null
    const data = await fetchProfileForUser(session.user.id)
    if (mountedRef.current) setProfile(data)
    return data
  }, [])

  const navigate = useNavigate()

  return (
    <AuthContext.Provider
      value={{
        profile,
        isLoading,
        isAuthenticated: !!profile,
        signIn,
        signOut,
        resetPassword,
        refetchProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
