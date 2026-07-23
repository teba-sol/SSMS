import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sscs_channel',
      'SSCS Notifications',
      channelDescription: 'Student Status Checkup System',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Register device token for push notifications
  Future<void> registerDeviceToken(String token) async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return;

    await AppSupabase.client.from(AppTables.deviceTokens).upsert({
      'user_id': userId,
      'token': token,
      'platform': 'android',
      'is_active': true,
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  /// Deactivate device token on logout
  Future<void> deactivateToken(String token) async {
    await AppSupabase.client
        .from(AppTables.deviceTokens)
        .update({
          'is_active': false,
          'logged_out_at': DateTime.now().toIso8601String(),
        })
        .eq('token', token);
  }

  /// Listen for new notifications in real-time
  Stream<List<Map<String, dynamic>>> notificationsStream(String userId) {
    return AppSupabase.client
        .from(AppTables.notifications)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
  }
}
