import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../models/profile_model.dart';
import '../../models/parent_model.dart';
import '../../supabase/supabase_client.dart';
import '../students/students_provider.dart';
import 'messages_provider.dart';

class MessagesPage extends ConsumerStatefulWidget {
  final bool isParent;
  const MessagesPage({super.key, this.isParent = false});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: widget.isParent
                ? _showNewConversationSheet
                : _showSelectStudentSheet,
            icon: const Icon(Icons.edit_outlined),
            tooltip: widget.isParent ? 'New Message' : 'Message a Parent',
          ),
        ],
      ),
      body: conversationsState.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyWidget(
              title: 'No Messages',
              subtitle: widget.isParent
                  ? 'Start a conversation with your child\'s teacher or contact admin support.'
                  : 'Select a student to message their parent.',
              icon: Icons.chat_bubble_outline_rounded,
              action: ElevatedButton.icon(
                onPressed: () => _ContactAdminTile.openAdminConversation(
                  context,
                  ref,
                  isParent: widget.isParent,
                ),
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: Text('Contact Support'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return _ContactAdminTile(isParent: widget.isParent);
              }
              final conv = conversations[i - 1];
              final currentUserId = AppSupabase.currentUser?.id ?? '';
              final other = conv.otherParticipant(currentUserId);

              return _ConversationTile(
                name: other?.fullName ?? 'Unknown',
                role: other?.role.name ?? '',
                lastMessage: conv.lastMessageContent ?? '',
                lastTime: conv.lastMessageAt,
                unread: conv.unreadCount,
                onTap: () => context.push(
                  widget.isParent
                      ? RouteNames.parentChat
                      : RouteNames.teacherChat,
                  extra: {
                    'conversationId': conv.id,
                    'otherUserId': conv.otherParticipantId(currentUserId),
                    'otherUserName': other?.fullName ?? 'Chat',
                    'otherUserRole': other?.role.name ?? '',
                  },
                ),
              );
            },
          );
        },
        loading: () => const ShimmerList(count: 5, itemHeight: 72),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // Teacher: show a list of their classes → students → pick parent
  void _showSelectStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SelectStudentParentSheet(),
    );
  }

  // Parent: generic user search
  void _showNewConversationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NewConversationSheet(isParent: true),
    );
  }
}

// ── Teacher: select student → then message their parent ──────────────────────

class _SelectStudentParentSheet extends ConsumerStatefulWidget {
  const _SelectStudentParentSheet();

  @override
  ConsumerState<_SelectStudentParentSheet> createState() =>
      _SelectStudentParentSheetState();
}

class _SelectStudentParentSheetState
    extends ConsumerState<_SelectStudentParentSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.family_restroom_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Message a Parent',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Select a student to find their parent',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Search student name...',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: assignmentsAsync.when(
                data: (assignments) {
                  final seen = <String>{};
                  final classIds = assignments
                      .where((a) => seen.add(a.classId))
                      .map((a) => a.classId)
                      .toList();

                  if (classIds.isEmpty) {
                    return const Center(
                      child: Text('No classes assigned',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }

                  return _AllStudentsForParentPicker(
                    classIds: classIds,
                    search: _search,
                    scrollCtrl: scrollCtrl,
                    onStudentSelected: (studentId, studentName) =>
                        _pickParentForStudent(studentId, studentName),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickParentForStudent(
      String studentId, String studentName) async {
    // Show parent selection for this student
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ParentPickerSheet(
        studentId: studentId,
        studentName: studentName,
        onParentSelected: (parentId, parentName) async {
          Navigator.pop(context); // close parent picker
          Navigator.pop(context); // close student picker
          final conv = await ref
              .read(conversationsProvider.notifier)
              .getOrCreate(parentId);
          if (conv != null && mounted) {
            context.push(RouteNames.teacherChat, extra: {
              'conversationId': conv.id,
              'otherUserId': parentId,
              'otherUserName': parentName,
              'otherUserRole': 'parent',
            });
          }
        },
      ),
    );
  }
}

class _AllStudentsForParentPicker extends ConsumerWidget {
  final List<String> classIds;
  final String search;
  final ScrollController scrollCtrl;
  final void Function(String, String) onStudentSelected;

  const _AllStudentsForParentPicker({
    required this.classIds,
    required this.search,
    required this.scrollCtrl,
    required this.onStudentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync =
        classIds.map((id) => ref.watch(classStudentsListProvider(id))).toList();

    if (allAsync.any((a) => a.isLoading)) {
      return const Center(child: CircularProgressIndicator());
    }

    final allStudents = <dynamic>[];
    final seen = <String>{};
    for (final async in allAsync) {
      async.whenData((students) {
        for (final s in students) {
          if (seen.add(s.id)) allStudents.add(s);
        }
      });
    }

    final filtered = search.isEmpty
        ? allStudents
        : allStudents
            .where((s) =>
                s.fullName.toLowerCase().contains(search.toLowerCase()) ||
                s.studentId.toLowerCase().contains(search.toLowerCase()))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          search.isEmpty ? 'No students found' : 'No results for "$search"',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final s = filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              s.firstName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(s.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle:
              Text('ID: ${s.studentId}', style: const TextStyle(fontSize: 12)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Select',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
          onTap: () => onStudentSelected(s.id, s.fullName),
        );
      },
    );
  }
}

class _ParentPickerSheet extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final void Function(String parentId, String parentName) onParentSelected;

  const _ParentPickerSheet({
    required this.studentId,
    required this.studentName,
    required this.onParentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsAsync = ref.watch(parentsForStudentProvider(studentId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text("$studentName's Parents",
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Select who you want to message',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          parentsAsync.when(
            data: (parents) {
              if (parents.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No parent linked to this student yet.\nAsk the administrator to link a parent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: parents.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.secondaryLight,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.secondary),
                    ),
                    title: Text(p.relationship.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Parent ID: ${p.parentId.substring(0, 8)}…',
                        style: const TextStyle(fontSize: 11)),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => onParentSelected(
                        p.parentId, '$studentName\'s ${p.relationship.label}'),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _ContactAdminTile extends ConsumerWidget {
  final bool isParent;

  const _ContactAdminTile({required this.isParent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.support_agent_rounded,
            color: AppColors.warning, size: 24),
      ),
      title: const Text('Contact Admin Support',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: const Text('For account or school-level concerns',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Support',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning)),
      ),
      onTap: () => openAdminConversation(context, ref, isParent: isParent),
    );
  }

  static Future<void> openAdminConversation(
    BuildContext context,
    WidgetRef ref, {
    required bool isParent,
  }) async {
    Profile? admin;
    try {
      admin = await ref.read(messagesServiceProvider).getAdminSupportContact();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to load admin support. Try again.')),
        );
      }
      return;
    }
    if (admin == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find admin contact')),
        );
      }
      return;
    }
    final conv =
        await ref.read(conversationsProvider.notifier).getOrCreate(admin.id);
    if (!context.mounted) return;
    if (conv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to start the support chat. Try again.')),
      );
      return;
    }
    context.push(isParent ? RouteNames.parentChat : RouteNames.teacherChat,
        extra: {
          'conversationId': conv.id,
          'otherUserId': admin.id,
          'otherUserName': admin.fullName,
          'otherUserRole': 'administrator',
        });
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String role;
  final String lastMessage;
  final DateTime? lastTime;
  final int unread;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.role,
    required this.lastMessage,
    this.lastTime,
    this.unread = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (role) {
      'teacher' => AppColors.primary,
      'parent' => AppColors.secondary,
      'administrator' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final roleLabel = switch (role) {
      'teacher' => 'Teacher',
      'parent' => 'Parent',
      'administrator' => 'Admin',
      _ => role,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(
                  color: roleColor, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                width: 10,
                height: 10,
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(roleLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: roleColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage.isEmpty ? 'No messages yet' : lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: unread > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (lastTime != null)
            Text(
              timeago.format(lastTime!, allowFromNow: true),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _NewConversationSheet extends ConsumerStatefulWidget {
  final bool isParent;
  const _NewConversationSheet({required this.isParent});

  @override
  ConsumerState<_NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState extends ConsumerState<_NewConversationSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchProvider(_query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('New Message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _query.trim().isEmpty
                  ? const Center(
                      child: Text('Type a name to search',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : searchAsync.when(
                      data: (users) => users.isEmpty
                          ? const Center(
                              child: Text('No users found',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)))
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: users.length,
                              itemBuilder: (_, i) {
                                final u = users[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(u.firstName
                                        .substring(0, 1)
                                        .toUpperCase()),
                                  ),
                                  title: Text(u.fullName),
                                  subtitle: Text(u.role.name,
                                      style: const TextStyle(fontSize: 12)),
                                  onTap: () => _startConversation(u),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation(Profile user) async {
    Navigator.pop(context);
    final conv =
        await ref.read(conversationsProvider.notifier).getOrCreate(user.id);
    if (conv != null && mounted) {
      context.push(
        widget.isParent ? RouteNames.parentChat : RouteNames.teacherChat,
        extra: {
          'conversationId': conv.id,
          'otherUserId': user.id,
          'otherUserName': user.fullName,
          'otherUserRole': user.role.name,
        },
      );
    }
  }
}
