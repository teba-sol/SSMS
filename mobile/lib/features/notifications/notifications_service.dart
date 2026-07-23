import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/notification_model.dart';

class NotificationsService {
  final _client = AppSupabase.client;

  Future<List<AppNotification>> getNotifications() async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from(AppTables.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from(AppTables.notifications)
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(AppTables.notifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Stream<List<Map<String, dynamic>>> notificationsStream() {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _client
        .from(AppTables.notifications)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
  }
}
