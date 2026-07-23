import 'package:dartz/dartz.dart';
import '../../models/announcement_model.dart';
import 'announcements_service.dart';

class AnnouncementsRepository {
  final AnnouncementsService _service;
  AnnouncementsRepository({AnnouncementsService? service})
      : _service = service ?? AnnouncementsService();

  Future<Either<String, List<Announcement>>> getAll() async {
    try {
      return Right(await _service.getAnnouncements());
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Unit>> markRead(String id) async {
    try {
      await _service.markAsRead(id);
      return const Right(unit);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, Announcement>> create({
    required String title,
    required String content,
    required String targetAudience,
    required String priority,
    String? classId,
  }) async {
    try {
      return Right(await _service.createAnnouncement(
        title: title,
        content: content,
        targetAudience: targetAudience,
        priority: priority,
        classId: classId,
      ));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
