import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          profile.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              profile.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outlined),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outlined),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.goNamed(RouteNames.login);
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
