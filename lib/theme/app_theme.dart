import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الرئيسية المستوحاة من الصورة بدقة
  static const Color sidebarNavy = Color(0xFF112239);
  static const Color sidebarNavyDark = Color(0xFF0C1726);
  static const Color sidebarActiveBlue = Color(0xFF2563EB);
  static const Color sidebarHover = Color(0xFF1E3A5F);
  static const Color sidebarTextMuted = Color(0xFF94A3B8);

  static const Color background = Color(0xFFF1F5F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEEF2F6);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ألوان المؤشرات (KPIs)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueSoft = Color(0xFFEFF6FF);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0xFFECFDF5);

  static const Color costPurple = Color(0xFF8B5CF6);
  static const Color costPurpleSoft = Color(0xFFF5F3FF);

  static const Color profitAmber = Color(0xFFF59E0B);
  static const Color profitAmberSoft = Color(0xFFFFFBEB);

  static const Color wasteRed = Color(0xFFEF4444);
  static const Color wasteRedSoft = Color(0xFFFEF2F2);

  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanSoft = Color(0xFFECFEFF);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceWhite,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Segoe UI',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: wasteRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: wasteRed, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: textSecondary),
        hintStyle: const TextStyle(fontSize: 12.5, color: textMuted),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
    );
  }
}
