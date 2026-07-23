import 'package:equatable/equatable.dart';
import 'profile_model.dart';

class Teacher extends Equatable {
  final String id;
  final String profileId;
  final String employeeId;
  final String? department;
  final String? qualification;
  final DateTime? hireDate;
  final bool isActive;
  final Profile? profile;

  const Teacher({
    required this.id,
    required this.profileId,
    required this.employeeId,
    this.department,
    this.qualification,
    this.hireDate,
    required this.isActive,
    this.profile,
  });

  String get displayName => profile?.fullName ?? employeeId;

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        employeeId: json['employee_id'] as String,
        department: json['department'] as String?,
        qualification: json['qualification'] as String?,
        hireDate: json['hire_date'] != null
            ? DateTime.parse(json['hire_date'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        profile: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, profileId, employeeId];
}

class TeacherAssignment extends Equatable {
  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final String academicYearId;
  final Map<String, dynamic>? classData;
  final Map<String, dynamic>? subjectData;
  final Map<String, dynamic>? academicYearData;

  const TeacherAssignment({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.academicYearId,
    this.classData,
    this.subjectData,
    this.academicYearData,
  });

  String get className => classData != null
      ? 'Grade ${classData!['grade_level']} ${classData!['section'] ?? ''}'
      : classId;

  String get subjectName => subjectData?['name'] as String? ?? subjectId;
  String get subjectCode => subjectData?['code'] as String? ?? '';
  String get academicYearName => academicYearData?['name'] as String? ?? '';

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) =>
      TeacherAssignment(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        classId: json['class_id'] as String,
        subjectId: json['subject_id'] as String,
        academicYearId: json['academic_year_id'] as String,
        classData: json['classes'] as Map<String, dynamic>?,
        subjectData: json['subjects'] as Map<String, dynamic>?,
        academicYearData: json['academic_years'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [id, teacherId, classId, subjectId];
}
