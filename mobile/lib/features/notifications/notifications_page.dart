import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../models/notification_model.dart';
import '../../models/announcement_model.dart';
import '../announcements/announcements_provider.dart';
import 'notifications_provider.dart';

/// A unified item shown in the notification center.
/// Can be either a system notification or an announcement.
class _FeedItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'announcement' | notification type
  final bool isRead;
  final DateTime createdAt;
  final AppNotification? notification;
  final Announcement? announcement;

  const _FeedItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.notification,
    this.announcement,
  });

  factory _FeedItem.fromNotification(AppNotification n) => _FeedItem(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: n.isRead,
        createdAt: n.createdAt,
        notification: n,
      );

  factory _FeedItem.fromAnnouncement(Announcement a) => _FeedItem(
        id: 'ann_${a.id}',
        title: a.title,
        body: a.content,
        type: 'announcement',
        isRead: a.isRead,
        createdAt: a.publishedAt ?? a.createdAt,
        announcement: a,
      );
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final announcState = ref.watch(announcementsProvider);

    // Build merged list
    final List<_FeedItem> feed = [];

    if (notifState case AsyncData(:final value)) {
      feed.addAll(value.map(_FeedItem.fromNotification));
    }
    if (announcState case AsyncData(:final value)) {
      // Only show published announcements
      feed.addAll(
        value
            .where((a) => a.isPublished)
            .map(_FeedItem.fromAnnouncement),
      );
    }

    // Sort newest-first
    feed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final isLoading = notifState is AsyncLoading || announcState is AsyncLoading;
    final hasError = notifState is AsyncError && announcState is AsyncError;

    Future<void> refresh() async {
      ref.read(notificationsProvider.notifier).refresh();
      ref.read(announcementsProvider.notifier).refresh();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: refresh,
            tooltip: 'Refresh',
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllRead();
              ref.read(announcementsProvider.notifier).markRead(
                    // Mark all announcements individually
                    '',
                  );
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: _buildBody(context, ref, feed, isLoading, hasError),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      List<_FeedItem> feed, bool isLoading, bool hasError) {
    if (isLoading && feed.isEmpty) {
      return const ShimmerList(count: 6, itemHeight: 80);
    }
    if (hasError && feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Failed to load notifications'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).refresh();
                ref.read(announcementsProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (feed.isEmpty) {
      return const EmptyWidget(
        title: 'No Notifications',
        subtitle: 'You\'re all caught up!',
        icon: Icons.notifications_off_outlined,
      );
    }

    // Group by "Today", "Yesterday", "Earlier"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String groupLabel(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) return 'Today';
      if (d == yesterday) return 'Yesterday';
      return 'Earlier';
    }

    // Build sections
    final sections = <String, List<_FeedItem>>{};
    for (final item in feed) {
      final label = groupLabel(item.createdAt);
      sections.putIfAbsent(label, () => []).add(item);
    }

    final sectionOrder = ['Today', 'Yesterday', 'Earlier'];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.entries.fold<int>(0, (sum, e) {
        final key = e.key;
        if (!sectionOrder.contains(key)) return sum;
        return sum + 1 + e.value.length; // header + items
      }),
      itemBuilder: (ctx, globalIndex) {
        int idx = 0;
        for (final section in sectionOrder) {
          final items = sections[section];
          if (items == null) continue;
          if (globalIndex == idx) {
            // Section header
            return _SectionHeader(label: section);
          }
          idx++;
          for (final item in items) {
            if (globalIndex == idx) {
              return _NotificationTile(
                item: item,
                onMarkRead: () {
                  if (item.notification != null) {
                    ref.read(notificationsProvider.notifier).markRead(item.notification!.id);
                  } else if (item.announcement != null) {
                    ref.read(announcementsProvider.notifier).markRead(item.announcement!.id);
                  }
                },
              );
            }
            idx++;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _FeedItem item;
  final VoidCallback onMarkRead;
  const _NotificationTile({required this.item, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = _iconForType(item.type);
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.success,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text('Read', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
      onDismissed: (_) => onMarkRead(),
      child: InkWell(
        onTap: !item.isRead ? onMarkRead : null,
        child: Container(
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.transparent
                : AppColors.primaryLight.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(
                color: item.isRead ? Colors.transparent : color,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _TypeChip(type: item.type, color: color),
                        const Spacer(),
                        Text(
                          timeago.format(item.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconForType(String type) {
    return switch (type) {
      'attendance' => (
          Icons.fact_check_rounded,
          AppColors.attendanceAbsent,
          AppColors.attendanceAbsentLight
        ),
      'result' =>
        (Icons.bar_chart_rounded, AppColors.secondary, AppColors.secondaryLight),
      'announcement' => (
          Icons.campaign_rounded,
          AppColors.warning,
          AppColors.warningLight
        ),
      'activity' =>
        (Icons.event_note_rounded, AppColors.success, AppColors.successLight),
      'message' =>
        (Icons.chat_bubble_rounded, AppColors.info, AppColors.infoLight),
      'system' =>
        (Icons.info_rounded, AppColors.textSecondary, AppColors.surfaceVariant),
      _ =>
        (Icons.notifications_rounded, AppColors.primary, AppColors.primaryLight),
    };
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'attendance' => 'Attendance',
      'result' => 'Result',
      'announcement' => 'Announcement',
      'activity' => 'Activity',
      'message' => 'Message',
      'system' => 'System',
      _ => 'Notification',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
