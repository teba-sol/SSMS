import 'package:equatable/equatable.dart';

enum AnnouncementPriority { low, normal, high, urgent }

extension AnnouncementPriorityX on AnnouncementPriority {
  String get value => name;
  String get label {
    switch (this) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  static AnnouncementPriority fromString(String val) =>
      AnnouncementPriority.values.firstWhere(
        (e) => e.value == val,
        orElse: () => AnnouncementPriority.normal,
      );
}

enum AnnouncementTarget { all, teachers, parents }

extension AnnouncementTargetX on AnnouncementTarget {
  String get value => name;
  String get label {
    switch (this) {
      case AnnouncementTarget.all:
        return 'Everyone';
      case AnnouncementTarget.teachers:
        return 'Teachers';
      case AnnouncementTarget.parents:
        return 'Parents';
    }
  }

  static AnnouncementTarget fromString(String val) =>
      AnnouncementTarget.values.firstWhere(
        (e) => e.value == val,
        orElse: () => AnnouncementTarget.all,
      );
}

class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final AnnouncementTarget targetAudience;
  final String? classId;
  final AnnouncementPriority priority;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? authorData;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.targetAudience,
    this.classId,
    required this.priority,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.authorData,
    this.isRead = false,
  });

  String get authorName {
    if (authorData == null) return 'Unknown';
    return '${authorData!['first_name']} ${authorData!['last_name']}';
  }

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        authorId: json['author_id'] as String,
        targetAudience:
            AnnouncementTargetX.fromString(json['target_audience'] as String),
        classId: json['class_id'] as String?,
        priority: AnnouncementPriorityX.fromString(json['priority'] as String),
        isPublished: json['is_published'] as bool? ?? false,
        publishedAt: json['published_at'] != null
            ? DateTime.parse(json['published_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        authorData: json['profiles'] as Map<String, dynamic>?,
        isRead: json['is_read'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, title, isPublished, isRead];
}
