import 'package:equatable/equatable.dart';

class AcademicYear extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  const AcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
        id: json['id'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        isCurrent: json['is_current'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, isCurrent];
}
