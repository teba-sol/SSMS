import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/profile_model.dart';
import '../auth/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final strings = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    // Determine correct fallback route based on role
    final fallback = profile?.role == UserRole.parent
        ? RouteNames.parentDashboard
        : RouteNames.teacherDashboard;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(fallback),
        ),
        title: Text(strings.settingsAndProfile),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: profile.role == UserRole.teacher
                        ? AppColors.teacherGradient
                        : AppColors.parentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          profile.firstName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17),
                          ),
                          Text(
                            profile.email,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile.role.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Edit profile
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  title: strings.editProfile,
                  subtitle: strings.editProfileDescription,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textHint),
                  onTap: () => context.push(RouteNames.editProfile),
                ),
                _Divider(),

                // Language
                _SectionHeader(strings.language),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: strings.language,
                  subtitle: locale.languageCode == 'am'
                      ? '${strings.amharic} (Amharic)'
                      : strings.english,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textHint),
                  onTap: () =>
                      _showLanguagePicker(context, ref, strings, locale),
                ),
                _Divider(),

                // Appearance
                _SectionHeader(strings.appearance),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: strings.darkMode,
                  subtitle: strings.systemDefault,
                  trailing: Switch(
                    value: ref.watch(themeProvider) == ThemeMode.dark,
                    onChanged: (value) =>
                        ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                ),
                _Divider(),

                // About
                _SectionHeader(strings.about),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: strings.appVersion,
                  subtitle: '1.0.0',
                ),
                _SettingsTile(
                  icon: Icons.school_outlined,
                  title: strings.school,
                  subtitle: strings.schoolName,
                ),
                _Divider(),

                // Sign out
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(strings.signOut),
                        content: Text(strings.signOutConfirmation),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(strings.cancel)),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                            child: Text(strings.signOut),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await authNotifier.signOut();
                      if (context.mounted) context.go(RouteNames.login);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(strings.signOut),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
    Locale selectedLocale,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.chooseLanguage,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(strings.languageDescription),
              const SizedBox(height: 8),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'en',
                groupValue: selectedLocale.languageCode,
                title: Text(strings.english),
                onChanged: (value) async {
                  if (value == null) return;
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(value));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'am',
                groupValue: selectedLocale.languageCode,
                title: Text(strings.amharic),
                subtitle: const Text('Amharic'),
                onChanged: (value) async {
                  if (value == null) return;
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(value));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(height: 20);
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: trailing,
        onTap: onTap,
      );
}
