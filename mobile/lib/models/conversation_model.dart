import 'package:equatable/equatable.dart';
import 'profile_model.dart';

class Conversation extends Equatable {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final Profile? participant1;
  final Profile? participant2;
  final String? lastMessageContent;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessageAt,
    required this.createdAt,
    this.participant1,
    this.participant2,
    this.lastMessageContent,
    this.unreadCount = 0,
  });

  Profile? otherParticipant(String currentUserId) {
    if (participant1Id == currentUserId) return participant2;
    return participant1;
  }

  String otherParticipantId(String currentUserId) {
    if (participant1Id == currentUserId) return participant2Id;
    return participant1Id;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        participant1Id: json['participant1_id'] as String,
        participant2Id: json['participant2_id'] as String,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        participant1: json['participant1'] != null
            ? Profile.fromJson(json['participant1'] as Map<String, dynamic>)
            : null,
        participant2: json['participant2'] != null
            ? Profile.fromJson(json['participant2'] as Map<String, dynamic>)
            : null,
        lastMessageContent: json['last_message'] as String?,
        unreadCount: json['unread_count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, participant1Id, participant2Id];
}
