import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String id;
  final String studentId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.studentId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName =>
      [firstName, if (middleName != null) middleName, lastName].join(' ');

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        firstName: json['first_name'] as String,
        middleName: json['middle_name'] as String?,
        lastName: json['last_name'] as String,
        dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        emergencyContact: json['emergency_contact'] as String?,
        emergencyPhone: json['emergency_phone'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props => [id, studentId, firstName, lastName];
}
