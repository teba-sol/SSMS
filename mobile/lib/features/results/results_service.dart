import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/result_model.dart';

class ResultsService {
  final _client = AppSupabase.client;

  Future<List<Result>> getResultsByAssignment(
      String teacherAssignmentId) async {
    final data = await _client
        .from(AppTables.results)
        .select(
            '*, students(first_name, last_name, student_id), teacher_assignments(classes(name, grade_level, section), subjects(name, code))')
        .eq('teacher_assignment_id', teacherAssignmentId)
        .order('exam_date', ascending: false);
    return (data as List).map((e) => Result.fromJson(e)).toList();
  }

  Future<List<Result>> getResultsByStudent(String studentId) async {
    final data = await _client
        .from(AppTables.results)
        .select(
            '*, teacher_assignments(classes(name, grade_level, section), subjects(name, code))')
        .eq('student_id', studentId)
        .order('exam_date', ascending: false);
    return (data as List).map((e) => Result.fromJson(e)).toList();
  }

  Future<Result> createResult(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppTables.results)
        .insert(data)
        .select(
            '*, students(first_name, last_name, student_id), teacher_assignments(classes(name, grade_level, section), subjects(name, code))')
        .single();
    final result = Result.fromJson(response);

    // Notify the student's parents
    await _notifyParents(result);

    return result;
  }

  Future<Result> updateResult(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(AppTables.results)
        .update(data)
        .eq('id', id)
        .select(
            '*, students(first_name, last_name, student_id), teacher_assignments(classes(name, grade_level, section), subjects(name, code))')
        .single();
    final result = Result.fromJson(response);

    // Notify parents of updated result too
    await _notifyParents(result, isUpdate: true);

    return result;
  }

  Future<void> deleteResult(String id) async {
    await _client.from(AppTables.results).delete().eq('id', id);
  }

  /// Sends an in-app notification to all active parents of the student.
  Future<void> _notifyParents(Result result, {bool isUpdate = false}) async {
    try {
      // Find parents linked to this student
      final parentLinks = await _client
          .from(AppTables.parentStudents)
          .select('parent_id, profiles!parent_students_parent_id_fkey(id)')
          .eq('student_id', result.studentId)
          .eq('is_active', true);

      if ((parentLinks as List).isEmpty) return;

      final studentName = result.studentName.isNotEmpty
          ? result.studentName
          : 'Your child';
      final subject = result.subjectName.isNotEmpty ? result.subjectName : 'a subject';
      final examLabel = result.examType.label;
      final score = result.marksObtained != null && result.totalMarks != null
          ? '${result.marksObtained!.toStringAsFixed(0)}/${result.totalMarks!.toStringAsFixed(0)}'
          : result.grade ?? 'recorded';

      final action = isUpdate ? 'updated' : 'added';
      final title = '$studentName — $examLabel $action';
      final body = '$examLabel result for $subject: $score'
          '${result.grade != null ? ' (${result.grade})' : ''}';

      final notifications = parentLinks.map((link) {
        // Support both joined and plain parent_id
        final parentId = link['parent_id'] as String;
        return {
          'user_id': parentId,
          'title': title,
          'body': body,
          'type': 'result',
          'is_read': false,
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _client.from(AppTables.notifications).insert(notifications);
      }
    } catch (_) {
      // Notification failure must not break result creation
    }
  }
}
