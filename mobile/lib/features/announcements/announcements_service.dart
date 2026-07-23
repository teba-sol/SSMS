import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/announcement_model.dart';

class AnnouncementsService {
  final _client = AppSupabase.client;

  Future<List<Announcement>> getAnnouncements({int limit = 30}) async {
    final userId = AppSupabase.currentUser?.id;
    final data = await _client
        .from(AppTables.announcements)
        .select('*, profiles!author_id(first_name, last_name)')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(limit);

    if (userId == null) {
      return (data as List).map((e) => Announcement.fromJson(e)).toList();
    }

    // Check which are read
    final reads = await _client
        .from(AppTables.announcementReads)
        .select('announcement_id')
        .eq('user_id', userId);

    final readIds = (reads as List)
        .map((r) => r['announcement_id'] as String)
        .toSet();

    return (data as List).map((e) {
      final a = Announcement.fromJson(e);
      return Announcement(
        id: a.id,
        title: a.title,
        content: a.content,
        authorId: a.authorId,
        targetAudience: a.targetAudience,
        classId: a.classId,
        priority: a.priority,
        isPublished: a.isPublished,
        publishedAt: a.publishedAt,
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
        authorData: a.authorData,
        isRead: readIds.contains(a.id),
      );
    }).toList();
  }

  Future<void> markAsRead(String announcementId) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return;
    await _client.from(AppTables.announcementReads).upsert({
      'announcement_id': announcementId,
      'user_id': userId,
    }, onConflict: 'announcement_id,user_id');
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required String targetAudience,
    required String priority,
    String? classId,
  }) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _client
        .from(AppTables.announcements)
        .insert({
          'title': title,
          'content': content,
          'author_id': userId,
          'target_audience': targetAudience,
          'priority': priority,
          if (classId != null) 'class_id': classId,
          'is_published': true,
          'published_at': DateTime.now().toIso8601String(),
        })
        .select('*, profiles!author_id(first_name, last_name)')
        .single();
    return Announcement.fromJson(data);
  }
}
