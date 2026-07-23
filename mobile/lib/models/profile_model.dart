import 'package:equatable/equatable.dart';

enum UserRole { administrator, teacher, parent }

class Profile extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final bool emailVerified;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] as String?)?.toLowerCase() ?? 'parent';
    final role = UserRole.values.firstWhere(
      (e) => e.name == rawRole,
      orElse: () => UserRole.parent,
    );

    final rawEmail = json['email'] as String? ?? '';
    final rawFirstName = json['first_name'] as String? ?? (rawEmail.contains('@') ? rawEmail.split('@').first : 'User');
    final rawLastName = json['last_name'] as String? ?? '';

    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      if (dateStr is DateTime) return dateStr;
      return DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    return Profile(
      id: json['id'] as String? ?? '',
      email: rawEmail,
      firstName: rawFirstName,
      lastName: rawLastName,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: role,
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      lastLogin: json['last_login'] != null ? parseDate(json['last_login']) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role.name,
      'is_active': isActive,
      'email_verified': emailVerified,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        avatarUrl,
        role,
        isActive,
        emailVerified,
        lastLogin,
        createdAt,
        updatedAt,
      ];
}
