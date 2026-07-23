import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle heading2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle heading3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.textPrimary);
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, color: AppColors.textSecondary);
  static const TextStyle caption = TextStyle(
    fontSize: 11, color: AppColors.textHint);
  static const TextStyle label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
}
