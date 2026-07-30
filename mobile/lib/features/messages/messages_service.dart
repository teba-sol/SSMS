import 'package:supabase_flutter/supabase_flutter.dart';
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

    final conversations =
        (data as List).map((e) => Conversation.fromJson(e)).toList();
    if (conversations.isEmpty) return conversations;

    final conversationIds =
        conversations.map((conversation) => conversation.id).toList();
    final messagesData = await _client
        .from(AppTables.messages)
        .select('conversation_id, content, created_at, sender_id, is_read')
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false);

    final latestByConversation = <String, Map<String, dynamic>>{};
    final unreadByConversation = <String, int>{};
    for (final rawMessage in messagesData as List) {
      final message = rawMessage as Map<String, dynamic>;
      final conversationId = message['conversation_id'] as String;
      latestByConversation.putIfAbsent(conversationId, () => message);

      if (message['sender_id'] != userId && message['is_read'] == false) {
        unreadByConversation[conversationId] =
            (unreadByConversation[conversationId] ?? 0) + 1;
      }
    }

    final inbox = conversations.map((conversation) {
      final latest = latestByConversation[conversation.id];
      final latestAt = latest?['created_at'] == null
          ? conversation.lastMessageAt
          : DateTime.parse(latest!['created_at'] as String);
      return Conversation(
        id: conversation.id,
        participant1Id: conversation.participant1Id,
        participant2Id: conversation.participant2Id,
        lastMessageAt: latestAt,
        createdAt: conversation.createdAt,
        participant1: conversation.participant1,
        participant2: conversation.participant2,
        lastMessageContent: latest?['content'] as String?,
        unreadCount: unreadByConversation[conversation.id] ?? 0,
      );
    }).toList();

    inbox.sort((a, b) {
      final aDate = a.lastMessageAt ?? a.createdAt;
      final bDate = b.lastMessageAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return inbox;
  }

  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Canonical ordering: smaller UUID first
    final p1 = userId.compareTo(otherUserId) < 0 ? userId : otherUserId;
    final p2 = userId.compareTo(otherUserId) < 0 ? otherUserId : userId;

    final existing = await _findConversation(p1, p2);

    if (existing != null) return existing;

    try {
      final created = await _client
          .from(AppTables.conversations)
          .insert({'participant1_id': p1, 'participant2_id': p2}).select('''
          *,
          participant1:profiles!participant1_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at),
          participant2:profiles!participant2_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at)
        ''').single();
      return Conversation.fromJson(created);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;

      final concurrentConversation = await _findConversation(p1, p2);
      if (concurrentConversation != null) return concurrentConversation;
      rethrow;
    }
  }

  Future<Conversation?> _findConversation(
      String participant1Id, String participant2Id) async {
    final data = await _client
        .from(AppTables.conversations)
        .select('''
          *,
          participant1:profiles!participant1_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at),
          participant2:profiles!participant2_id(id, email, first_name, last_name, role, avatar_url, phone, is_active, email_verified, last_login, created_at, updated_at)
        ''')
        .eq('participant1_id', participant1Id)
        .eq('participant2_id', participant2Id)
        .maybeSingle();
    return data == null ? null : Conversation.fromJson(data);
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

  Future<Message> sendMessage(String conversationId, String content) async {
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

  Future<Profile?> getAdminSupportContact() async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from(AppTables.profiles)
        .select()
        .eq('role', 'administrator')
        .eq('is_active', true)
        .neq('id', userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    return data == null ? null : Profile.fromJson(data);
  }
}
