import 'package:equatable/equatable.dart';
import 'student_model.dart';

enum RelationshipType { father, mother, guardian, other }

extension RelationshipTypeX on RelationshipType {
  String get value => name;
  String get label {
    switch (this) {
      case RelationshipType.father:
        return 'Father';
      case RelationshipType.mother:
        return 'Mother';
      case RelationshipType.guardian:
        return 'Guardian';
      case RelationshipType.other:
        return 'Other';
    }
  }

  static RelationshipType fromString(String val) =>
      RelationshipType.values.firstWhere(
        (e) => e.value == val,
        orElse: () => RelationshipType.guardian,
      );
}

class ParentStudent extends Equatable {
  final String id;
  final String parentId;
  final String studentId;
  final RelationshipType relationship;
  final bool isPrimary;
  final bool isActive;
  final Student? student;

  const ParentStudent({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.relationship,
    required this.isPrimary,
    required this.isActive,
    this.student,
  });

  factory ParentStudent.fromJson(Map<String, dynamic> json) => ParentStudent(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        studentId: json['student_id'] as String,
        relationship:
            RelationshipTypeX.fromString(json['relationship'] as String),
        isPrimary: json['is_primary'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        student: json['students'] != null
            ? Student.fromJson(json['students'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, parentId, studentId];
}
