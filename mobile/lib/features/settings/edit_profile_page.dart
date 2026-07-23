import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile_model.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _phoneCtrl.text = profile.phone ?? '';
      _emailCtrl.text = profile.email;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    // Update profile fields
    final updated = profile.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    // Update email if changed
    final newEmail = _emailCtrl.text.trim();
    final emailChanged = newEmail.isNotEmpty && newEmail != profile.email;
    // Update password if provided
    final newPassword = _passwordCtrl.text;
    final passwordProvided = newPassword.isNotEmpty;
    final repo = ref.read(authRepositoryProvider);
    // Perform profile update first
    final profileResult = await repo.updateProfile(updated);
    profileResult.fold(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile update error: $err'), backgroundColor: AppColors.error));
      },
      (_) async {
        // Email update
        if (emailChanged) {
          final emailRes = await repo.updateEmail(newEmail);
          emailRes.fold(
            (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email update error: $err'), backgroundColor: AppColors.error)),
            (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email updated'), backgroundColor: AppColors.success)),
          );
        }
        // Password update
        if (passwordProvided) {
          final passRes = await repo.updatePassword(newPassword);
          passRes.fold(
            (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password update error: $err'), backgroundColor: AppColors.error)),
            (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success)),
          );
        }
        // Refresh auth state
        ref.read(authProvider.notifier).refreshProfile();
        if (mounted) context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(labelText: 'New Password (optional)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      keyboardType: TextInputType.phone,
                    ),
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
