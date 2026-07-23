import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String academicYearId;
  final String name;
  final int gradeLevel;
  final String? section;
  final int capacity;
  final String? room;
  final bool isActive;

  const ClassModel({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.gradeLevel,
    this.section,
    required this.capacity,
    this.room,
    required this.isActive,
  });

  String get displayName => section != null ? 'Grade $gradeLevel - $section' : 'Grade $gradeLevel';

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'] as String,
        academicYearId: json['academic_year_id'] as String,
        name: json['name'] as String,
        gradeLevel: json['grade_level'] as int,
        section: json['section'] as String?,
        capacity: json['capacity'] as int? ?? 40,
        room: json['room'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, gradeLevel, section];
}
