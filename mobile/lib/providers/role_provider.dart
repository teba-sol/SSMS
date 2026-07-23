import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../features/auth/auth_provider.dart';

export '../models/profile_model.dart' show UserRole;

final isTeacherProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile?.role == UserRole.teacher || profile?.role == UserRole.administrator;
});

final isParentProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile?.role == UserRole.parent;
});
