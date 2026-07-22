import { useState, useRef, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { useMessages, useSendMessage } from './useMessages'
import { messageService } from './messageService'
import Breadcrumb from '@/components/Breadcrumb'
import Spinner from '@/components/Spinner'
import Button from '@/components/Button'
import { ArrowLeft, Send } from 'lucide-react'
import { formatDateTime } from '@/utils/formatters'
import type { ConversationWithRelations } from './messageTypes'

export default function ConversationChatPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { profile } = useAuth()
  const { data: messages = [], isLoading: loadingMessages } = useMessages(id ?? '')
  const sendMessage = useSendMessage()
  const [newMessage, setNewMessage] = useState('')
  const [conversation, setConversation] = useState<ConversationWithRelations | null>(null)
  const [loadingConvo, setLoadingConvo] = useState(true)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!id) return
    setLoadingConvo(true)
    messageService
      .getConversations(profile?.id ?? '')
      .then((convos) => {
        const found = convos.find((c: ConversationWithRelations) => c.id === id)
        setConversation(found ?? null)
      })
      .finally(() => setLoadingConvo(false))
  }, [id, profile?.id])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = () => {
    if (!newMessage.trim() || !id || !profile) return
    sendMessage.mutate(
      { conversationId: id, senderId: profile.id, content: newMessage.trim() },
      { onSuccess: () => setNewMessage('') },
    )
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const other = conversation
    ? conversation.participant1?.id === profile?.id
      ? conversation.participant2
      : conversation.participant1
    : null

  if (loadingMessages || loadingConvo) return <Spinner />

  return (
    <div className="flex flex-col h-[calc(100vh-2rem)]">
      <Breadcrumb
        items={[
          { label: 'Dashboard', to: '/dashboard' },
          { label: 'Messages', to: '/messages' },
          { label: other ? `${other.first_name} ${other.last_name}` : 'Chat' },
        ]}
      />

      <div className="flex items-center gap-3 mb-4">
        <button onClick={() => navigate('/messages')} className="p-1 hover:bg-slate-100 rounded-lg">
          <ArrowLeft size={20} className="text-slate-600" />
        </button>
        <div className="h-9 w-9 rounded-full bg-primary-100 flex items-center justify-center">
          <span className="text-sm font-semibold text-primary-600">{other?.first_name?.[0]?.toUpperCase()}</span>
        </div>
        <div>
          <p className="text-sm font-medium text-slate-900">{other?.first_name} {other?.last_name}</p>
          <p className="text-xs text-slate-500 capitalize">{other?.role}</p>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto bg-white rounded-xl border border-slate-200 p-4 mb-4">
        {messages.length === 0 ? (
          <p className="text-sm text-slate-400 text-center py-12">No messages yet. Say hello!</p>
        ) : (
          <div className="space-y-3">
            {messages.map((msg) => {
              const isMine = msg.sender_id === profile?.id
              return (
                <div key={msg.id} className={`flex ${isMine ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[70%] px-4 py-2 rounded-2xl text-sm ${
                    isMine
                      ? 'bg-primary-500 text-white rounded-br-md'
                      : 'bg-slate-100 text-slate-900 rounded-bl-md'
                  }`}>
                    <p>{msg.content}</p>
                    <p className={`text-[10px] mt-1 ${isMine ? 'text-primary-200' : 'text-slate-400'}`}>
                      {formatDateTime(msg.created_at)}
                    </p>
                  </div>
                </div>
              )
            })}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      <div className="flex items-center gap-2">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Type a message..."
          className="flex-1 px-4 py-2.5 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
        <Button onClick={handleSend} disabled={!newMessage.trim() || sendMessage.isPending}>
          <Send size={16} />
        </Button>
      </div>
    </div>
  )
}
