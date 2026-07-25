import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/priority_badge.dart';
import '../../models/announcement_model.dart';
import '../auth/auth_provider.dart';
import 'announcements_provider.dart';

class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsState = ref.watch(announcementsProvider);
    final profile = ref.watch(currentProfileProvider);

    final fallback = profile?.role.name == 'parent'
        ? RouteNames.parentDashboard
        : RouteNames.teacherDashboard;

    Future<void> refresh() => ref.read(announcementsProvider.notifier).refresh();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
        ),
        title: const Text('Announcements'),
        actions: [
          IconButton(
            onPressed: refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          if (profile?.role.name == 'teacher')
            IconButton(
              onPressed: () => context.push(RouteNames.teacherAnnouncementAdd),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create Announcement',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: announcementsState.when(
          data: (announcements) {
            if (announcements.isEmpty) {
              return const EmptyWidget(
                title: 'No Announcements',
                subtitle: 'School announcements will appear here.',
                icon: Icons.campaign_outlined,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (ctx, i) =>
                  _AnnouncementCard(announcement: announcements[i]),
            );
          },
          loading: () => const ShimmerList(count: 4, itemHeight: 140),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = switch (announcement.priority) {
      AnnouncementPriority.urgent => AppColors.error,
      AnnouncementPriority.high => AppColors.warning,
      AnnouncementPriority.normal => AppColors.primary,
      AnnouncementPriority.low => AppColors.textSecondary,
    };

    return GestureDetector(
      onTap: () {
        if (!announcement.isRead) {
          ref.read(announcementsProvider.notifier).markRead(announcement.id);
        }
        _showDetail(context, announcement);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: announcement.isRead ? AppColors.border : priorityColor.withValues(alpha: 0.3),
            width: announcement.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Priority stripe
            Container(
              width: 4,
              height: 100,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PriorityBadge(priority: announcement.priority),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            announcement.targetAudience.label,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                        const Spacer(),
                        if (!announcement.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontWeight: announcement.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          announcement.authorName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, yyyy')
                              .format(announcement.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Announcement a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PriorityBadge(priority: a.priority),
              const SizedBox(height: 12),
              Text(a.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('By ${a.authorName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text('•',
                      style: const TextStyle(color: AppColors.textHint)),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(a.createdAt),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(a.content,
                  style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
