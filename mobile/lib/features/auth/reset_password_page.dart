import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../supabase/supabase_client.dart';
import 'auth_repository.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSuccess = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _handleRecovery();
  }

  void _handleRecovery() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final accessToken = uri.queryParameters['access_token'];

    if (accessToken != null) {
      AppSupabase.auth.setSession(accessToken);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref
        .read(authRepositoryProvider)
        .updatePassword(_passwordController.text);

    result.fold(
      (error) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          setState(() => _isSuccess = true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Password Updated',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your password has been updated successfully.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.goNamed(RouteNames.login);
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New Password',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your new password below.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdatePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text('Update Password'),
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
