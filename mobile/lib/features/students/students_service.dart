import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../models/parent_model.dart';

class StudentsService {
  final _client = AppSupabase.client;

  /// Get the teacher record for the current user
  Future<Teacher?> getCurrentTeacher() async {
    final userId = AppSupabase.currentUser?.id;
    if (userId == null) return null;

    final teacherData = await _client
        .from(AppTables.teachers)
        .select('id, profile_id, employee_id, department, qualification, hire_date, is_active')
        .eq('profile_id', userId)
        .maybeSingle();

    if (teacherData == null) return null;

    final profileData = await _client
        .from(AppTables.profiles)
        .select()
        .eq('id', teacherData['profile_id'] as String)
        .maybeSingle();

    final json = Map<String, dynamic>.from(teacherData);
    if (profileData != null) {
      json['profiles'] = profileData;
    }

    return Teacher.fromJson(json);
  }

  /// Get all assignments for the current teacher
  Future<List<TeacherAssignment>> getTeacherAssignments(String teacherId) async {
    final data = await _client
        .from(AppTables.teacherAssignments)
        .select(
            'id, teacher_id, class_id, subject_id, academic_year_id, '
            'classes(id, name, grade_level, section, capacity, room, is_active, academic_year_id), '
            'subjects(id, name, code, description), '
            'academic_years(id, name, is_current)')
        .eq('teacher_id', teacherId);

    final assignments = (data as List).map((e) => TeacherAssignment.fromJson(e)).toList();

    final missingClassData = assignments.any((a) => a.classData == null);
    final missingSubjectData = assignments.any((a) => a.subjectData == null);

    if (!missingClassData && !missingSubjectData) return assignments;

    Map<String, Map<String, dynamic>> classMap = {};
    Map<String, Map<String, dynamic>> subjectMap = {};

    if (missingClassData) {
      final classIds = assignments.map((a) => a.classId).toSet().toList();
      final classData = await _client
          .from(AppTables.classes)
          .select('id, name, grade_level, section')
          .inFilter('id', classIds);
      for (final c in classData as List) {
        classMap[c['id'] as String] = c as Map<String, dynamic>;
      }
    }

    if (missingSubjectData) {
      final subjectIds = assignments.map((a) => a.subjectId).toSet().toList();
      final subjectData = await _client
          .from(AppTables.subjects)
          .select('id, name, code, description')
          .inFilter('id', subjectIds);
      for (final s in subjectData as List) {
        subjectMap[s['id'] as String] = s as Map<String, dynamic>;
      }
    }

    return assignments.map((a) => TeacherAssignment(
      id: a.id,
      teacherId: a.teacherId,
      classId: a.classId,
      subjectId: a.subjectId,
      academicYearId: a.academicYearId,
      classData: a.classData ?? classMap[a.classId],
      subjectData: a.subjectData ?? subjectMap[a.subjectId],
      academicYearData: a.academicYearData,
    )).toList();
  }

  /// Get all students in a class.
  ///
  /// Uses a TWO-STEP fetch to avoid Supabase RLS infinite recursion:
  ///   Step 1 → query student_enrollments for the class_id (gets student IDs only).
  ///   Step 2 → query students by those IDs.
  ///
  /// Direct embedding (student_enrollments → students) triggers the parent_students
  /// RLS policy chain which loops back on itself (code 42P17).
  Future<List<Student>> getStudentsInClass(String classId) async {
    // Step 1: Get just the student IDs enrolled in this class
    final enrollments = await _client
        .from(AppTables.studentEnrollments)
        .select('student_id')
        .eq('class_id', classId)
        .eq('status', 'active');

    final studentIds = (enrollments as List)
        .map((e) => (e as Map<String, dynamic>)['student_id'] as String)
        .toList();

    if (studentIds.isEmpty) return [];

    // Step 2: Fetch full student records by their IDs
    final data = await _client
        .from(AppTables.students)
        .select('id, student_id, first_name, middle_name, last_name, date_of_birth, gender, address, emergency_contact, emergency_phone, created_at, updated_at')
        .inFilter('id', studentIds)
        .order('last_name')
        .order('first_name');

    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get children linked to a parent.
  ///
  /// Also uses a TWO-STEP fetch — embedding students inside parent_students
  /// creates the same RLS recursion loop (parent_students → students RLS →
  /// parent_students again).
  Future<List<ParentStudent>> getChildrenForParent(String parentId) async {
    // Step 1: Get parent-student link records (no student embedding)
    final psData = await _client
        .from(AppTables.parentStudents)
        .select('id, parent_id, student_id, relationship, is_primary, is_active')
        .eq('parent_id', parentId)
        .eq('is_active', true);

    final psList = (psData as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    if (psList.isEmpty) return [];

    // Step 2: Fetch students separately by their IDs
    final studentIds = psList.map((e) => e['student_id'] as String).toList();
    final studentsData = await _client
        .from(AppTables.students)
        .select('id, student_id, first_name, middle_name, last_name, date_of_birth, gender, address, emergency_contact, emergency_phone, created_at, updated_at')
        .inFilter('id', studentIds);

    final studentsMap = <String, Map<String, dynamic>>{};
    for (final s in studentsData as List) {
      final sm = s as Map<String, dynamic>;
      studentsMap[sm['id'] as String] = sm;
    }

    return psList.map((ps) {
      return ParentStudent.fromJson({
        ...ps,
        'students': studentsMap[ps['student_id'] as String],
      });
    }).toList();
  }

  /// Get parents linked to a specific student (for teacher use)
  Future<List<ParentStudent>> getParentsForStudent(String studentId) async {
    final data = await _client
        .from(AppTables.parentStudents)
        .select('id, parent_id, student_id, relationship, is_primary, is_active')
        .eq('student_id', studentId)
        .eq('is_active', true);
    return (data as List).map((e) => ParentStudent.fromJson(e)).toList();
  }

  /// Get current class enrollment for a student
  Future<Map<String, dynamic>?> getStudentCurrentClass(String studentId) async {
    final data = await _client
        .from(AppTables.studentEnrollments)
        .select('*, classes(id, name, grade_level, section, academic_year_id, academic_years(name, is_current))')
        .eq('student_id', studentId)
        .eq('status', 'active')
        .maybeSingle();
    return data;
  }
}
