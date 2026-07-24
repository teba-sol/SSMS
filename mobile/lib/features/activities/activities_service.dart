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
        .isFilter('student_id', null) // class-wide only
        .order('activity_date', ascending: false)
        .limit(limit);

    final data = await query;
    final activities = (data as List).map((e) => Activity.fromJson(e)).toList();
    if (classId == null) return activities;
    return activities.where((a) => a.classId == null || a.classId == classId).toList();
  }

  /// Student-specific logs (behavior, participation, etc.)
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

    // Fetch class-wide + student-specific logs
    final data = await _client
        .from(AppTables.activities)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .or('student_id.eq.$studentId,student_id.is.null')
        .order('activity_date', ascending: false)
        .limit(50);

    final all = (data as List).map((e) => Activity.fromJson(e)).toList();
    return all
        .where((a) =>
            a.studentId == studentId ||
            (a.studentId == null &&
                (a.classId == null || classIds.contains(a.classId))))
        .toList();
  }

  Future<Activity> createActivity(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppTables.activities)
        .insert(data)
        .select('*, profiles!organizer_id(first_name, last_name)')
        .single();
    final activity = Activity.fromJson(response);

    // If this is a student-specific log, notify parents
    if (activity.studentId != null) {
      await _notifyParents(activity);
    }

    return activity;
  }

  Future<void> deleteActivity(String id) async {
    await _client.from(AppTables.activities).delete().eq('id', id);
  }

  Future<void> _notifyParents(Activity activity) async {
    try {
      final parentLinks = await _client
          .from(AppTables.parentStudents)
          .select('parent_id')
          .eq('student_id', activity.studentId!)
          .eq('is_active', true);

      if ((parentLinks as List).isEmpty) return;

      final typePretty = activity.activityType
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');

      final title = 'New log: ${activity.title}';
      final body = '$typePretty logged on '
          '${activity.activityDate.day}/${activity.activityDate.month}/${activity.activityDate.year}'
          '${activity.description != null ? ' — ${activity.description}' : ''}';

      final notifications = parentLinks.map((link) => {
            'user_id': link['parent_id'] as String,
            'title': title,
            'body': body,
            'type': 'activity',
            'is_read': false,
          }).toList();

      await _client.from(AppTables.notifications).insert(notifications);
    } catch (_) {
      // Don't let notification failure break the log creation
    }
  }
}
