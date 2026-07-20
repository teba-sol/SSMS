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

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final response = await _client
        .from(AppTables.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }
}
