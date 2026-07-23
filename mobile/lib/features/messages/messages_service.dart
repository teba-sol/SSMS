import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/profile_model.dart';

class MessagesService {
  final _client = AppSupabase.client;

  Future<List<Conversation>> getConversations() async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from(AppTables.conversations)
        .select('''
          *,
          participant1:profiles!participant1_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at),
          participant2:profiles!participant2_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at)
        ''')
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
        .order('last_message_at', ascending: false, nullsFirst: false);

    return (data as List).map((e) => Conversation.fromJson(e)).toList();
  }

  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Canonical ordering: smaller UUID first
    final p1 = userId.compareTo(otherUserId) < 0 ? userId : otherUserId;
    final p2 = userId.compareTo(otherUserId) < 0 ? otherUserId : userId;

    // Check existing
    final existing = await _client
        .from(AppTables.conversations)
        .select('''
          *,
          participant1:profiles!participant1_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at),
          participant2:profiles!participant2_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at)
        ''')
        .eq('participant1_id', p1)
        .eq('participant2_id', p2)
        .maybeSingle();

    if (existing != null) return Conversation.fromJson(existing);

    // Create new
    final created = await _client
        .from(AppTables.conversations)
        .insert({'participant1_id': p1, 'participant2_id': p2})
        .select('''
          *,
          participant1:profiles!participant1_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at),
          participant2:profiles!participant2_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at)
        ''')
        .single();
    return Conversation.fromJson(created);
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final data = await _client
        .from(AppTables.messages)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => Message.fromJson(e)).toList();
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from(AppTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((e) => Message.fromJson(e)).toList());
  }

  Future<Message> sendMessage(
      String conversationId, String content) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _client
        .from(AppTables.messages)
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
        })
        .select()
        .single();

    // Update last_message_at
    await _client
        .from(AppTables.conversations)
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return Message.fromJson(data);
  }

  Future<void> markMessagesRead(String conversationId) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(AppTables.messages)
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  Future<List<Profile>> searchUsersToMessage(String query) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(AppTables.profiles)
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%,email.ilike.%$query%')
        .neq('id', userId)
        .eq('is_active', true)
        .limit(20);
    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }
}
