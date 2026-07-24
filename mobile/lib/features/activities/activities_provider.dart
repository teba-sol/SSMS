import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_model.dart';
import '../../supabase/supabase_client.dart';
import 'activities_service.dart';

final activitiesServiceProvider =
    Provider<ActivitiesService>((ref) => ActivitiesService());

// For teachers — class-wide activities by class
final classActivitiesProvider =
    FutureProvider.family<List<Activity>, String>((ref, classId) async {
  return ref.read(activitiesServiceProvider).getActivities(classId: classId);
});

// Student-specific behavior/participation logs (teacher view)
final studentLogsProvider =
    FutureProvider.family<List<Activity>, String>((ref, studentId) async {
  return ref.read(activitiesServiceProvider).getStudentLogs(studentId);
});

// For parents — class + student-specific activities
final studentActivitiesProvider =
    FutureProvider.family<List<Activity>, String>((ref, studentId) async {
  return ref.read(activitiesServiceProvider).getActivitiesForStudent(studentId);
});

class ActivitiesNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> create({
    required String title,
    required String? description,
    required String activityType,
    required DateTime activityDate,
    String? location,
    String? classId,
    String? studentId,
    required String academicYearId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = AppSupabase.currentUser?.id;
      await ref.read(activitiesServiceProvider).createActivity({
        'title': title,
        if (description != null) 'description': description,
        'activity_type': activityType,
        'activity_date': activityDate.toIso8601String().split('T')[0],
        if (location != null) 'location': location,
        'organizer_id': userId,
        if (classId != null) 'class_id': classId,
        if (studentId != null) 'student_id': studentId,
        'academic_year_id': academicYearId,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activitiesNotifierProvider =
    NotifierProvider<ActivitiesNotifier, AsyncValue<void>>(
  ActivitiesNotifier.new,
);
