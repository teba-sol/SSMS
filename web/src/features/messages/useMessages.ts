import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { messageService } from './messageService'

export function useConversations(userId: string) {
  return useQuery({
    queryKey: ['conversations', userId],
    queryFn: () => messageService.getConversations(userId),
    enabled: !!userId,
  })
}

export function useMessages(conversationId: string) {
  return useQuery({
    queryKey: ['messages', conversationId],
    queryFn: () => messageService.getMessages(conversationId),
    enabled: !!conversationId,
  })
}

export function useSendMessage() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ conversationId, senderId, content }: { conversationId: string; senderId: string; content: string }) =>
      messageService.sendMessage(conversationId, senderId, content),
    onSuccess: (_, vars) => {
      queryClient.invalidateQueries({ queryKey: ['messages', vars.conversationId] })
      queryClient.invalidateQueries({ queryKey: ['conversations'] })
    },
  })
}

export function useStartConversation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ userId1, userId2 }: { userId1: string; userId2: string }) =>
      messageService.startConversation(userId1, userId2),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['conversations'] })
    },
  })
}
