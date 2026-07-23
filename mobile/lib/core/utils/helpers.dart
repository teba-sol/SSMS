import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  static String formatDate(DateTime dt) =>
      DateFormat('MMM d, yyyy').format(dt);

  static String formatDateFull(DateTime dt) =>
      DateFormat('EEEE, MMMM d, yyyy').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String toIsoDate(DateTime dt) =>
      dt.toIso8601String().split('T').first;

  static String gradeFromPercentage(double pct) {
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'A-';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'B-';
    if (pct >= 65) return 'C+';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
