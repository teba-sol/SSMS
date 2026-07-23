import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFF5F3FF);
  static const Color accent = Color(0xFF0EA5E9);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFEA580C);
  static const Color warningLight = Color(0xFFFFF7ED);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Surfaces (light)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text (light)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Attendance
  static const Color attendancePresent = Color(0xFF16A34A);
  static const Color attendancePresentLight = Color(0xFFF0FDF4);
  static const Color attendanceAbsent = Color(0xFFDC2626);
  static const Color attendanceAbsentLight = Color(0xFFFEF2F2);
  static const Color attendanceLate = Color(0xFFEA580C);
  static const Color attendanceLateLight = Color(0xFFFFF7ED);
  static const Color attendanceExcused = Color(0xFF0EA5E9);
  static const Color attendanceExcusedLight = Color(0xFFF0F9FF);

  // Grade colors
  static const Color gradeA = Color(0xFF16A34A);
  static const Color gradeB = Color(0xFF0EA5E9);
  static const Color gradeC = Color(0xFFEAB308);
  static const Color gradeD = Color(0xFFEA580C);
  static const Color gradeF = Color(0xFFDC2626);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient teacherGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient parentGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
