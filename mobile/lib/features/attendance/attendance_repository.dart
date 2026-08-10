import 'package:dartz/dartz.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import 'attendance_service.dart';

class AttendanceRepository {
  final AttendanceService _service;
  AttendanceRepository({AttendanceService? service})
      : _service = service ?? AttendanceService();

  Future<Either<String, List<Attendance>>> getByClassAndDate(
      String classId, String date) async {
    try {
      return Right(await _service.getByClassAndDate(classId, date));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<Student>>> getStudentsForClass(
      String classId) async {
    try {
      return Right(await _service.getStudentsForClass(classId));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Unit>> upsertAttendance(
      List<Map<String, dynamic>> records) async {
    try {
      await _service.upsertAttendance(records);
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<Attendance>>> getStudentAttendance({
    required String studentId,
    String? classId,
    int limit = 50,
    DateTime? fromDate,
  }) async {
    try {
      return Right(await _service.getStudentAttendance(
          studentId: studentId,
          classId: classId,
          limit: limit,
          fromDate: fromDate));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Map<String, int>>> getAttendanceSummary(
      String studentId) async {
    try {
      return Right(await _service.getAttendanceSummaryForStudent(studentId));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
