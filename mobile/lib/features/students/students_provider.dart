import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../models/parent_model.dart';
import '../../supabase/supabase_client.dart';
import 'students_service.dart';

final studentsServiceProvider =
    Provider<StudentsService>((ref) => StudentsService());

/// Current teacher record
final currentTeacherProvider = FutureProvider<Teacher?>((ref) async {
  return ref.read(studentsServiceProvider).getCurrentTeacher();
});

/// All assignments for the current teacher
final teacherAssignmentsProvider =
    FutureProvider<List<TeacherAssignment>>((ref) async {
  final teacherAsync = await ref.watch(currentTeacherProvider.future);
  if (teacherAsync == null) return [];
  return ref
      .read(studentsServiceProvider)
      .getTeacherAssignments(teacherAsync.id);
});

/// Students in a specific class — uses RPC to avoid parent_students RLS recursion
final classStudentsListProvider =
    FutureProvider.family<List<Student>, String>((ref, classId) async {
  return ref.read(studentsServiceProvider).getStudentsInClass(classId);
});



/// Parents linked to a specific student (for teacher messaging)
final parentsForStudentProvider =
    FutureProvider.family<List<ParentStudent>, String>((ref, studentId) async {
  return ref.read(studentsServiceProvider).getParentsForStudent(studentId);
});

/// Children for the current parent
final parentChildrenProvider =
    FutureProvider<List<ParentStudent>>((ref) async {
  final userId = AppSupabase.currentUser?.id;
  if (userId == null) return [];
  return ref.read(studentsServiceProvider).getChildrenForParent(userId);
});

/// Student's current class enrollment info
final studentCurrentClassProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, studentId) async {
  return ref.read(studentsServiceProvider).getStudentCurrentClass(studentId);
});
