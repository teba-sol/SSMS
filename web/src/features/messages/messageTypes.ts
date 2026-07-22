export interface Conversation {
  id: string
  participant1_id: string
  participant2_id: string
  last_message_at: string | null
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  content: string
  is_read: boolean
  created_at: string
}

export interface ConversationWithRelations extends Conversation {
  participant1?: { id: string; first_name: string; last_name: string; email: string; role: string } | null
  participant2?: { id: string; first_name: string; last_name: string; email: string; role: string } | null
  last_message?: { content: string; sender_id: string; created_at: string } | null
}
