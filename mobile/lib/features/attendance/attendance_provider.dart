import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import 'attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepository());

// Fetch students for a class
final classStudentsProvider =
    FutureProvider.family<List<Student>, String>((ref, classId) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final result = await repo.getStudentsForClass(classId);
  return result.fold((e) => throw Exception(e), (v) => v);
});

// Fetch attendance for class+date
final classAttendanceProvider = FutureProvider.family<List<Attendance>,
    ({String classId, String date})>((ref, args) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final result = await repo.getByClassAndDate(args.classId, args.date);
  return result.fold((e) => throw Exception(e), (v) => v);
});

// Student's attendance history
final studentAttendanceProvider =
    FutureProvider.family<List<Attendance>, String>((ref, studentId) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final result =
      await repo.getStudentAttendance(studentId: studentId);
  return result.fold((e) => throw Exception(e), (v) => v);
});

// Attendance summary for a student
final studentAttendanceSummaryProvider =
    FutureProvider.family<Map<String, int>, String>((ref, studentId) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final result = await repo.getAttendanceSummary(studentId);
  return result.fold((e) => throw Exception(e), (v) => v);
});

// Notifier for marking attendance
class MarkAttendanceNotifier
    extends FamilyNotifier<AsyncValue<void>, String> {
  @override
  AsyncValue<void> build(String arg) => const AsyncValue.data(null);

  Future<void> mark(List<Map<String, dynamic>> records) async {
    state = const AsyncValue.loading();
    final repo = ref.read(attendanceRepositoryProvider);
    final result = await repo.upsertAttendance(records);
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}

final markAttendanceProvider = NotifierProvider.family<
    MarkAttendanceNotifier, AsyncValue<void>, String>(
  MarkAttendanceNotifier.new,
);
