import 'package:equatable/equatable.dart';

class Activity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String activityType;
  final DateTime activityDate;
  final String? location;
  final String? organizerId;
  final String? classId;
  final String academicYearId;
  final DateTime createdAt;
  final Map<String, dynamic>? organizerData;

  const Activity({
    required this.id,
    required this.title,
    this.description,
    required this.activityType,
    required this.activityDate,
    this.location,
    this.organizerId,
    this.classId,
    required this.academicYearId,
    required this.createdAt,
    this.organizerData,
  });

  String get organizerName {
    if (organizerData == null) return 'School';
    return '${organizerData!['first_name']} ${organizerData!['last_name']}';
  }

  bool get isSchoolWide => classId == null;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        activityType: json['activity_type'] as String,
        activityDate: DateTime.parse(json['activity_date'] as String),
        location: json['location'] as String?,
        organizerId: json['organizer_id'] as String?,
        classId: json['class_id'] as String?,
        academicYearId: json['academic_year_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        organizerData: json['profiles'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toInsertJson() => {
        'title': title,
        'description': description,
        'activity_type': activityType,
        'activity_date': activityDate.toIso8601String().split('T')[0],
        'location': location,
        'organizer_id': organizerId,
        if (classId != null) 'class_id': classId,
        'academic_year_id': academicYearId,
      };

  @override
  List<Object?> get props => [id, title, activityDate];
}
