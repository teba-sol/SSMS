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
    return result;
  }

  Future<void> deleteResult(String id) async {
    await _client.from(AppTables.results).delete().eq('id', id);
  }
}
