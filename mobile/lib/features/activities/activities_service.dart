import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/activity_model.dart';

class ActivitiesService {
  final _client = AppSupabase.client;

  Future<List<Activity>> getActivities({
    String? classId,
    int limit = 30,
  }) async {
    final data = await _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .order('activity_date', ascending: false)
        .limit(limit);
    final activities = (data as List).map((e) => Activity.fromJson(e)).toList();
    if (classId == null) return activities;
    return activities.where((a) => a.classId == null || a.classId == classId).toList();
  }

  Future<List<Activity>> getActivitiesForStudent(String studentId) async {
    // Get student's class IDs first
    final enrollments = await _client
        .from(AppTables.studentEnrollments)
        .select('class_id')
        .eq('student_id', studentId)
        .eq('status', 'active');

    final classIds = (enrollments as List)
        .map((e) => e['class_id'] as String)
        .toList();

    final data = await _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .order('activity_date', ascending: false)
        .limit(30);

    final all = (data as List).map((e) => Activity.fromJson(e)).toList();
    return all
        .where((a) => a.classId == null || classIds.contains(a.classId))
        .toList();
  }

  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppTables.activities)
        .insert(data)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .single();
    return Activity.fromJson(response);
  }

  Future<void> deleteActivity(String id) async {
    await _client.from(AppTables.activities).delete().eq('id', id);
  }
}
