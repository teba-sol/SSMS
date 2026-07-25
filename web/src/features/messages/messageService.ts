import { supabase } from '@/supabase/client'

export const messageService = {
  async getConversations(userId: string) {
    const { data, error } = await supabase
      .from('conversations')
      .select(`
        *,
        participant1:profiles!participant1_id(id, first_name, last_name, email, role),
        participant2:profiles!participant2_id(id, first_name, last_name, email, role)
      `)
      .or(`participant1_id.eq.${userId},participant2_id.eq.${userId}`)
      .order('last_message_at', { ascending: false, nullsFirst: false })

    if (error) throw error
    return data ?? []
  },

  async getMessages(conversationId: string) {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(100)

    if (error) throw error
    return data ?? []
  },

  async sendMessage(conversationId: string, senderId: string, content: string) {
    const { data, error } = await supabase
      .from('messages')
      .insert({ conversation_id: conversationId, sender_id: senderId, content })
      .select()
      .single()
    if (error) throw error

    await supabase
      .from('conversations')
      .update({ last_message_at: new Date().toISOString() })
      .eq('id', conversationId)

    return data
  },

  async startConversation(userId1: string, userId2: string) {
    const [p1, p2] = userId1 < userId2 ? [userId1, userId2] : [userId2, userId1]
    const { data: existing } = await supabase
      .from('conversations')
      .select('id')
      .eq('participant1_id', p1)
      .eq('participant2_id', p2)
      .single()

    if (existing) return existing.id

    const { data, error } = await supabase
      .from('conversations')
      .insert({ participant1_id: p1, participant2_id: p2 })
      .select()
      .single()
    if (error) throw error
    return data.id
  },
}
