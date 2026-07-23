import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';

class AuthService {
  final SupabaseClient _client = AppSupabase.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.sscsmobile://reset-password',
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Build a Profile-compatible map from the JWT claims alone.
  /// Reads role from app_metadata first (set by create-user edge function),
  /// then falls back to user_metadata (set by seed SQL).
  /// This avoids querying the profiles table during login, which would
  /// trigger the recursive RLS bug.
  Map<String, dynamic>? buildProfileFromJwt(User user) {
    final appMeta = user.appMetadata;
    final userMeta = user.userMetadata ?? {};

    // Role: app_metadata wins, then user_metadata, default to 'parent'
    final role = (appMeta['role'] as String?)?.isNotEmpty == true
        ? appMeta['role'] as String
        : (userMeta['role'] as String?)?.isNotEmpty == true
            ? userMeta['role'] as String
            : 'parent';

    final firstName = (userMeta['first_name'] as String?) ??
        (user.email?.split('@').first ?? 'User');
    final lastName = (userMeta['last_name'] as String?) ?? '';

    final now = DateTime.now().toIso8601String();

    return {
      'id': user.id,
      'email': user.email ?? '',
      'first_name': firstName,
      'last_name': lastName,
      'phone': userMeta['phone'] as String?,
      'avatar_url': userMeta['avatar_url'] as String?,
      'role': role,
      'is_active': true,
      'email_verified': user.emailConfirmedAt != null,
      'last_login': now,
      'created_at': user.createdAt.isNotEmpty ? user.createdAt : now,
      'updated_at': now,
    };
  }

  /// Try to fetch the profile from the database.
  /// Returns null on any error (RLS, network, etc.) without throwing.
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from(AppTables.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }
}
