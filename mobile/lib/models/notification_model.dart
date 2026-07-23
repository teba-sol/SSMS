import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceType,
    this.referenceId,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        referenceType: json['reference_type'] as String?,
        referenceId: json['reference_id'] as String?,
        actionUrl: json['action_url'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        referenceType: referenceType,
        referenceId: referenceId,
        actionUrl: actionUrl,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, isRead];
}
