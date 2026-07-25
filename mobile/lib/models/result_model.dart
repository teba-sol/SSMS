import 'package:equatable/equatable.dart';

enum ExamType { midterm, final_, quiz, assignment, project }

extension ExamTypeX on ExamType {
  String get label {
    switch (this) {
      case ExamType.midterm:
        return 'Midterm';
      case ExamType.final_:
        return 'Final';
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.assignment:
        return 'Assignment';
      case ExamType.project:
        return 'Project';
    }
  }

  String get value {
    switch (this) {
      case ExamType.midterm:
        return 'midterm';
      case ExamType.final_:
        return 'final';
      case ExamType.quiz:
        return 'quiz';
      case ExamType.assignment:
        return 'assignment';
      case ExamType.project:
        return 'project';
    }
  }

  static ExamType fromString(String val) {
    return ExamType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => ExamType.quiz,
    );
  }
}

class Result extends Equatable {
  final String id;
  final String studentId;
  final String teacherAssignmentId;
  final double? marksObtained;
  final double? totalMarks;
  final String? grade;
  final ExamType examType;
  final DateTime examDate;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? studentData;
  final Map<String, dynamic>? assignmentData;

  const Result({
    required this.id,
    required this.studentId,
    required this.teacherAssignmentId,
    this.marksObtained,
    this.totalMarks,
    this.grade,
    required this.examType,
    required this.examDate,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.studentData,
    this.assignmentData,
  });

  String get studentName {
    if (studentData == null) return studentId;
    return '${studentData!['first_name']} ${studentData!['last_name']}';
  }

  String get studentNumber => studentData?['student_id'] as String? ?? '';

  String get subjectName {
    final subjects = assignmentData?['subjects'];
    return subjects?['name'] as String? ?? '';
  }

  String get className {
    final classes = assignmentData?['classes'];
    if (classes == null) return '';
    // Always build from grade_level + section for consistent display
    final grade = classes['grade_level'];
    final section = classes['section'] as String?;
    if (grade != null) {
      return section != null && section.isNotEmpty
          ? 'Grade $grade Section $section'
          : 'Grade $grade';
    }
    // Fallback to name field
    final name = classes['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return '';
  }

  double? get percentage {
    if (marksObtained == null || totalMarks == null || totalMarks == 0) {
      return null;
    }
    return (marksObtained! / totalMarks!) * 100;
  }

  String get displayScore {
    if (marksObtained != null && totalMarks != null) {
      return '${marksObtained!.toStringAsFixed(1)} / ${totalMarks!.toStringAsFixed(1)}';
    }
    return grade ?? 'N/A';
  }

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        teacherAssignmentId: json['teacher_assignment_id'] as String,
        marksObtained: (json['marks_obtained'] as num?)?.toDouble(),
        totalMarks: (json['total_marks'] as num?)?.toDouble(),
        grade: json['grade'] as String?,
        examType: ExamTypeX.fromString(json['exam_type'] as String),
        examDate: DateTime.parse(json['exam_date'] as String),
        remarks: json['remarks'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        studentData: json['students'] as Map<String, dynamic>?,
        assignmentData: json['teacher_assignments'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [id, studentId, teacherAssignmentId, examType, examDate];
}
