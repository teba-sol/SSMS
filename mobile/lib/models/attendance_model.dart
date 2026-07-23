import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.excused:
        return 'excused';
    }
  }

  static AttendanceStatus fromString(String val) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

class Attendance extends Equatable {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final String? notes;
  final Map<String, dynamic>? studentData;
  final Map<String, dynamic>? classData;

  const Attendance({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.notes,
    this.studentData,
    this.classData,
  });

  String get studentName {
    if (studentData == null) return studentId;
    return '${studentData!['first_name']} ${studentData!['last_name']}';
  }

  String get studentNumber => studentData?['student_id'] as String? ?? '';

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        classId: json['class_id'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatusX.fromString(json['status'] as String),
        markedBy: json['marked_by'] as String,
        notes: json['notes'] as String?,
        studentData: json['students'] as Map<String, dynamic>?,
        classData: json['classes'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toUpsertJson() => {
        'student_id': studentId,
        'class_id': classId,
        'date': date.toIso8601String().split('T')[0],
        'status': status.value,
        'marked_by': markedBy,
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => [id, studentId, classId, date, status];
}

// Used when marking attendance — tracks per-student status in the form
class AttendanceDraft {
  final String studentId;
  final String studentName;
  final String studentNumber;
  AttendanceStatus status;
  String? notes;
  String? existingId;

  AttendanceDraft({
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    this.status = AttendanceStatus.present,
    this.notes,
    this.existingId,
  });
}
