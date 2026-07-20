import 'package:dartz/dartz.dart';
import '../../models/profile_model.dart';
import 'auth_service.dart';

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
        return const Left('No user found');
      }

      final profileData = await _service.fetchProfile(response.user!.id);

      if (profileData == null) {
        return const Left('Profile not found. Contact administrator.');
      }

      final profile = Profile.fromJson(profileData);

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

  Future<Either<String, Profile>> getCurrentProfile() async {
    try {
      final user = _service.currentUser;
      if (user == null) {
        return const Left('Not authenticated');
      }

      final profileData = await _service.fetchProfile(user.id);

      if (profileData == null) {
        return const Left('Profile not found');
      }

      return Right(Profile.fromJson(profileData));
    } catch (e) {
      return Left(_parseError(e));
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
