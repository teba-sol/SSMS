import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';

class AttendanceService {
  final _client = AppSupabase.client;

  Future<List<Attendance>> getByClassAndDate(String classId, String date) async {
    final data = await _client
        .from(AppTables.attendance)
        .select('*, students(first_name, last_name, student_id)')
        .eq('class_id', classId)
        .eq('date', date);
    return (data as List).map((e) => Attendance.fromJson(e)).toList();
  }

  Future<List<Student>> getStudentsForClass(String classId) async {
    final data = await _client
        .from(AppTables.studentEnrollments)
        .select('students(id, student_id, first_name, middle_name, last_name, date_of_birth, gender, address, emergency_contact, emergency_phone, created_at, updated_at)')
        .eq('class_id', classId)
        .eq('status', 'active');
    return (data as List)
        .map((e) => Student.fromJson(e['students'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertAttendance(List<Map<String, dynamic>> records) async {
    await _client
        .from(AppTables.attendance)
        .upsert(records, onConflict: 'student_id,class_id,date');
  }

  Future<List<Attendance>> getAttendanceHistory({
    required String classId,
    int limit = 30,
  }) async {
    final data = await _client
        .from(AppTables.attendance)
        .select('*, students(first_name, last_name, student_id)')
        .eq('class_id', classId)
        .order('date', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Attendance.fromJson(e)).toList();
  }

  Future<Map<String, int>> getAttendanceSummaryForStudent(
      String studentId) async {
    final data = await _client
        .from(AppTables.attendance)
        .select('status')
        .eq('student_id', studentId);

    final summary = {
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
    };

    for (final row in data as List) {
      final status = row['status'] as String;
      summary[status] = (summary[status] ?? 0) + 1;
    }
    return summary;
  }

  Future<List<Attendance>> getStudentAttendance({
    required String studentId,
    String? classId,
    int limit = 50,
  }) async {
    var query = _client
        .from(AppTables.attendance)
        .select('*, classes(name, grade_level, section)')
        .eq('student_id', studentId);

    if (classId != null) {
      query = query.eq('class_id', classId);
    }

    final data = await query.order('date', ascending: false).limit(limit);
    return (data as List).map((e) => Attendance.fromJson(e)).toList();
  }
}
