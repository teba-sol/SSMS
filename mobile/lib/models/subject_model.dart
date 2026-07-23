import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, code];
}
