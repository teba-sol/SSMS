import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import 'notifications_service.dart';

final notificationsServiceProvider =
    Provider<NotificationsService>((ref) => NotificationsService());

// Real-time stream provider
final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final service = ref.read(notificationsServiceProvider);
  return service.notificationsStream().map(
        (list) => list.map((e) => AppNotification.fromJson(e)).toList(),
      );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final stream = ref.watch(notificationsStreamProvider);
  return stream.value?.where((n) => !n.isRead).length ?? 0;
});

class NotificationsNotifier
    extends Notifier<AsyncValue<List<AppNotification>>> {
  @override
  AsyncValue<List<AppNotification>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final data =
          await ref.read(notificationsServiceProvider).getNotifications();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> markRead(String id) async {
    await ref.read(notificationsServiceProvider).markAsRead(id);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsServiceProvider).markAllAsRead();
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>(
  NotificationsNotifier.new,
);
