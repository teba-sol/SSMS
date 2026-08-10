class RouteNames {
  RouteNames._();

  // Auth
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherAttendanceMark = '/teacher/attendance/mark';
  static const String teacherResults = '/teacher/results';
  static const String teacherResultAdd = '/teacher/results/add';
  static const String teacherActivities = '/teacher/activities';
  static const String teacherActivityAdd = '/teacher/activities/add';
  static const String teacherMessages = '/teacher/messages';
  static const String teacherChat = '/teacher/messages/chat';
  static const String teacherAnnouncements = '/teacher/announcements';
  static const String teacherAnnouncementAdd = '/teacher/announcements/add';
  static const String teacherNotifications = '/teacher/notifications';
  static const String teacherStudents = '/teacher/students';
  static const String teacherClasses = '/teacher/classes';
  static const String teacherStudentDetail = '/teacher/students/detail';
  static const String teacherProfile = '/teacher/profile';

  // Parent
  static const String parentDashboard = '/parent/dashboard';
  static const String parentResults = '/parent/results';
  static const String parentAttendance = '/parent/attendance';
  static const String parentActivities = '/parent/activities';
  static const String parentMessages = '/parent/messages';
  static const String parentChat = '/parent/messages/chat';
  static const String parentNotifications = '/parent/notifications';
  static const String parentAnnouncements = '/parent/announcements';
  static const String parentProfile = '/parent/profile';

  // Shared
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
}
