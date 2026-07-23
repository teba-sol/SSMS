import { supabase } from '@/supabase/client'

export const api = {
  supabase,

  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  },

  async getCurrentProfile() {
    const user = await this.getCurrentUser()
    if (!user) return null
    const { data } = await supabase.from('profiles').select('*').eq('id', user.id).single()
    return data
  },
}
