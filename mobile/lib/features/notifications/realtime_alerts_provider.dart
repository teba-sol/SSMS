import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../auth/auth_provider.dart';
import 'notifications_provider.dart';

final realtimeAlertsProvider = NotifierProvider<RealtimeAlertsNotifier, void>(
  RealtimeAlertsNotifier.new,
);

class RealtimeAlertsNotifier extends Notifier<void> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  final _knownNotificationIds = <String>{};
  var _receivedInitialSnapshot = false;

  @override
  void build() {
    final profile = ref.watch(currentProfileProvider);
    _subscription?.cancel();
    _subscription = null;
    _knownNotificationIds.clear();
    _receivedInitialSnapshot = false;

    if (profile == null) return;

    final service = ref.read(notificationsServiceProvider);
    _subscription = service.notificationsStream().listen(
          _handleNotifications,
          onError: (_, __) {},
        );
    ref.onDispose(() => _subscription?.cancel());
  }

  Future<void> _handleNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final notificationIds = notifications
        .map((notification) => notification['id'] as String?)
        .whereType<String>()
        .toSet();

    if (!_receivedInitialSnapshot) {
      _knownNotificationIds.addAll(notificationIds);
      _receivedInitialSnapshot = true;
      return;
    }

    final newNotifications = notifications.where((notification) {
      final id = notification['id'] as String?;
      return id != null && !_knownNotificationIds.contains(id);
    });
    _knownNotificationIds.addAll(notificationIds);

    for (final notification in newNotifications) {
      await NotificationService().showLocalNotification(
        title: notification['title'] as String? ?? 'New update',
        body: notification['body'] as String? ?? '',
        payload: notification['action_url'] as String?,
      );
    }
  }
}
