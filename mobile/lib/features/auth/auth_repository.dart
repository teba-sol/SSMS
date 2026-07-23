import 'package:dartz/dartz.dart';
import '../../models/profile_model.dart';
import 'auth_service.dart';
import '../../supabase/supabase_tables.dart';
import '../../supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository({AuthService? service}) : _service = service ?? AuthService();

  Future<Either<String, Profile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Left('No account found. Contact your administrator.');
      }

      final user = response.user!;

      // Strategy 1: try the profiles table (works when RLS is healthy)
      final profileData = await _service.fetchProfile(user.id);

      Map<String, dynamic> data;
      if (profileData != null) {
        data = profileData;
      } else {
        // Strategy 2: build profile from JWT claims
        // This works even when the profiles table RLS is broken
        final jwtProfile = _service.buildProfileFromJwt(user);
        if (jwtProfile == null) {
          await _service.signOut();
          return const Left('Could not load your profile. Contact your administrator.');
        }
        data = jwtProfile;
      }

      final profile = Profile.fromJson(data);

      if (!profile.isActive) {
        await _service.signOut();
        return const Left('Account is deactivated. Contact administrator.');
      }

      return Right(profile);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Unit>> resetPassword(String email) async {
    try {
      await _service.resetPasswordForEmail(email);
      return const Right(unit);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Unit>> updateEmail(String newEmail) async {
    try {
      await AppSupabase.client.auth.updateUser(UserAttributes(email: newEmail));
      return const Right(unit);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Unit>> updatePassword(String newPassword) async {
    try {
      await _service.updatePassword(newPassword);
      return const Right(unit);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Unit>> signOut() async {
    try {
      await _service.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Unit>> updateProfile(Profile profile) async {
    try {
      await AppSupabase.client.from(AppTables.profiles).upsert(profile.toJson());
      return const Right(unit);
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  Future<Either<String, Profile>> getCurrentProfile() async {
    try {
      final user = _service.currentUser;
      if (user == null) {
        return const Left('Not authenticated');
      }

      // Try DB first, fall back to JWT
      final profileData = await _service.fetchProfile(user.id);
      if (profileData != null) {
        return Right(Profile.fromJson(profileData));
      }

      final jwtProfile = _service.buildProfileFromJwt(user);
      if (jwtProfile != null) {
        return Right(Profile.fromJson(jwtProfile));
      }

      return const Left('Profile not found');
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  String _parseError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('email not confirmed') ||
        msg.contains('not confirmed') ||
        msg.contains('confirmation')) {
      return 'Email not confirmed. Ask your administrator to confirm your account.';
    }
    if (msg.contains('invalid_credentials') ||
        msg.contains('invalid login') ||
        (msg.contains('invalid') && msg.contains('password')) ||
        msg.contains('wrong password')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('user not found') ||
        msg.contains('no user') ||
        msg.contains('does not exist')) {
      return 'No account found with this email. Contact your administrator.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout')) {
      return 'Network error. Check your internet connection.';
    }
    if (msg.contains('too many') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait and try again.';
    }
    if (msg.contains('profile not found')) {
      return 'Profile not found. Contact your administrator.';
    }
    return error.toString();
  }
}
