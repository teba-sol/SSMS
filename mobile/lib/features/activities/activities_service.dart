import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/activity_model.dart';

class ActivitiesService {
  final _client = AppSupabase.client;

  Future<List<Activity>> getActivities({
    String? classId,
    int limit = 30,
  }) async {
    var query = _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .isFilter('student_id', null)
        .order('activity_date', ascending: false)
        .limit(limit);

    final data = await query;
    final activities = (data as List).map((e) => Activity.fromJson(e)).toList();
    if (classId == null) return activities;
    return activities.where((a) => a.classId == null || a.classId == classId).toList();
  }

  /// Personal logs for a single student.
  Future<List<Activity>> getStudentLogs(String studentId) async {
    final data = await _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .eq('student_id', studentId)
        .order('activity_date', ascending: false)
        .limit(50);
    return (data as List).map((e) => Activity.fromJson(e)).toList();
  }

  Future<List<Activity>> getActivitiesForStudent(String studentId) async {
    // Get student's class IDs
    final enrollments = await _client
        .from(AppTables.studentEnrollments)
        .select('class_id')
        .eq('student_id', studentId)
        .eq('status', 'active');

    final classIds = (enrollments as List)
        .map((e) => e['class_id'] as String)
        .toList();

    // Fetch activities for the student's enrolled classes and school-wide ones.
    final data = await _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .order('activity_date', ascending: false)
        .limit(50);

    final all = (data as List).map((e) => Activity.fromJson(e)).toList();
    return all.where((activity) {
      if (activity.studentId != null) return activity.studentId == studentId;
      return activity.classId == null || classIds.contains(activity.classId);
    }).toList();
  }

  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppTables.activities)
        .insert(data)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .single();
    final activity = Activity.fromJson(response);

    return activity;
  }

  Future<void> deleteActivity(String id) async {
    await _client.from(AppTables.activities).delete().eq('id', id);
  }
}
