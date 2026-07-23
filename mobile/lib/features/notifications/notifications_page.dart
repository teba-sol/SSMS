import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import 'notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: notifState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyWidget(
              title: 'No Notifications',
              subtitle: 'You\'re all caught up!',
              icon: Icons.notifications_off_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final n = notifications[i];
              final (icon, color, bg) = _iconForType(n.type);
              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.check_rounded, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(notificationsProvider.notifier).markRead(n.id),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  trailing: !n.isRead
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    if (!n.isRead) {
                      ref.read(notificationsProvider.notifier).markRead(n.id);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const ShimmerList(count: 6, itemHeight: 80),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  (IconData, Color, Color) _iconForType(String type) {
    return switch (type) {
      'attendance' => (Icons.fact_check_rounded, AppColors.attendanceAbsent, AppColors.attendanceAbsentLight),
      'result' => (Icons.bar_chart_rounded, AppColors.secondary, AppColors.secondaryLight),
      'announcement' => (Icons.campaign_rounded, AppColors.primary, AppColors.primaryLight),
      'activity' => (Icons.event_note_rounded, AppColors.success, AppColors.successLight),
      'message' => (Icons.chat_bubble_rounded, AppColors.info, AppColors.infoLight),
      'system' => (Icons.info_rounded, AppColors.textSecondary, AppColors.surfaceVariant),
      _ => (Icons.notifications_rounded, AppColors.primary, AppColors.primaryLight),
    };
  }
}
