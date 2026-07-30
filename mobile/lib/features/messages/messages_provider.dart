import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/profile_model.dart';
import '../../core/services/realtime_sync.dart';
import 'messages_service.dart';

final messagesServiceProvider =
    Provider<MessagesService>((ref) => MessagesService());

// All conversations for the current user
class ConversationsNotifier extends Notifier<AsyncValue<List<Conversation>>> {
  @override
  AsyncValue<List<Conversation>> build() {
    ref.listen<int>(realtimeSyncProvider, (_, __) => _load());
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(messagesServiceProvider).getConversations();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<Conversation?> getOrCreate(String otherUserId) async {
    try {
      final conv = await ref
          .read(messagesServiceProvider)
          .getOrCreateConversation(otherUserId);
      await _load();
      return conv;
    } catch (_) {
      return null;
    }
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>(
        ConversationsNotifier.new);

// Real-time messages stream for a conversation
final messagesStreamProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.read(messagesServiceProvider).messagesStream(conversationId);
});

// User search for new conversation
final userSearchProvider =
    FutureProvider.family<List<Profile>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ref.read(messagesServiceProvider).searchUsersToMessage(query);
});

// Total unread message count
final unreadMessagesCountProvider = Provider<int>((ref) {
  final convState = ref.watch(conversationsProvider);
  return convState.value?.fold<int>(0, (sum, c) => sum + c.unreadCount) ?? 0;
});
