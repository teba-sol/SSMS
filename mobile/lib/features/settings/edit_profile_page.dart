import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      _phoneCtrl.text = profile.phone ?? '';
      _emailCtrl.text = profile.email;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;

    final newEmail = _emailCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final newPassword = _passwordCtrl.text;
    final emailChanged = newEmail.isNotEmpty && newEmail != profile.email;
    final phoneChanged = newPhone != (profile.phone ?? '');
    final passwordProvided = newPassword.isNotEmpty;

    final repo = ref.read(authRepositoryProvider);

    // Update phone if changed
    if (phoneChanged) {
      final updated = profile.copyWith(phone: newPhone.isEmpty ? null : newPhone);
      final profileResult = await repo.updateProfile(updated);
      profileResult.fold(
        (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error)),
        (_) {},
      );
    }

    // Email update
    if (emailChanged) {
      final emailRes = await repo.updateEmail(newEmail);
      emailRes.fold(
        (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email error: $err'), backgroundColor: AppColors.error)),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated'), backgroundColor: AppColors.success)),
      );
    }

    // Password update
    if (passwordProvided) {
      final passRes = await repo.updatePassword(newPassword);
      passRes.fold(
        (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password error: $err'), backgroundColor: AppColors.error)),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success)),
      );
    }

    ref.read(authProvider.notifier).refreshProfile();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Read-only name display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              profile?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const Text('Name cannot be changed here', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact info section
                    const Text('Contact Information', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Password section
                    const Text('Change Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'New Password (optional)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      validator: (v) {
                        if (_passwordCtrl.text.isNotEmpty && v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
