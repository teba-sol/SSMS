import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/announcement_model.dart';
import 'announcements_repository.dart';

final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((ref) => AnnouncementsRepository());

class AnnouncementsNotifier extends Notifier<AsyncValue<List<Announcement>>> {
  @override
  AsyncValue<List<Announcement>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await ref.read(announcementsRepositoryProvider).getAll();
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (v) => state = AsyncValue.data(v),
    );
  }

  Future<void> refresh() => _load();

  Future<void> markRead(String id) async {
    await ref.read(announcementsRepositoryProvider).markRead(id);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current
          .map((a) => a.id == id
              ? Announcement(
                  id: a.id,
                  title: a.title,
                  content: a.content,
                  authorId: a.authorId,
                  targetAudience: a.targetAudience,
                  classId: a.classId,
                  priority: a.priority,
                  isPublished: a.isPublished,
                  publishedAt: a.publishedAt,
                  createdAt: a.createdAt,
                  updatedAt: a.updatedAt,
                  authorData: a.authorData,
                  isRead: true,
                )
              : a)
          .toList(),
    );
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String targetAudience,
    required String priority,
    String? classId,
  }) async {
    final result = await ref.read(announcementsRepositoryProvider).create(
          title: title,
          content: content,
          targetAudience: targetAudience,
          priority: priority,
          classId: classId,
        );
    result.fold(
      (e) => null,
      (a) {
        final current = state.value ?? [];
        state = AsyncValue.data([a, ...current]);
      },
    );
  }
}

final announcementsProvider =
    NotifierProvider<AnnouncementsNotifier, AsyncValue<List<Announcement>>>(
  AnnouncementsNotifier.new,
);

final unreadAnnouncementsCountProvider = Provider<int>((ref) {
  final state = ref.watch(announcementsProvider);
  return state.value?.where((a) => !a.isRead).length ?? 0;
});
