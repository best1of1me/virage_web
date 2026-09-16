import 'package:flutter/material.dart';
import '../services/web_storage.dart';

class AppTheme {
  // الألوان الأساسية للوضع الفاتح
  static const Color primaryBlue = Color(0xFF0F4C81);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkSlate = Color(0xFF2C3E50);
  static const Color bgGrey = Color(0xFFF4F6F8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFCFD8DC);

  // الألوان الأساسية للوضع الداكن
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkText = Color(0xFFE0E0E0);

  // 1. الثيم الفاتح (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgGrey,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: cardWhite,
        onPrimary: Colors.white,
        onSurface: darkSlate,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: darkSlate, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: darkSlate, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: darkSlate, height: 1.5),
        bodySmall: TextStyle(color: darkSlate, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        labelStyle: const TextStyle(color: darkSlate),
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIconColor: primaryBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 2. الثيم الداكن (Dark Theme)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.dark,
        primary: accentBlue,
        secondary: primaryBlue,
        surface: darkCard,
        onPrimary: Colors.white,
        onSurface: darkText,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: darkText, height: 1.5),
        bodySmall: TextStyle(color: darkText, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 3,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        labelStyle: const TextStyle(color: darkText),
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: accentBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlue,
          side: const BorderSide(color: accentBlue),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// 3. كلاس التحكم في نمط الثيم
// يدعم حفظ اختيار المستخدم (فاتح/داكن/تلقائي) في التخزين المحلي للمتصفح
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(_loadSavedMode());

  static const String _storageKey = 'virage_theme_mode';

  /// قراءة النمط المحفوظ من WebStorage (Web فقط).
  static ThemeMode _loadSavedMode() {
    final saved = WebStorage.read(_storageKey);
    switch (saved) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// حفظ النمط الحالي في WebStorage.
  void _persist(ThemeMode mode) {
    WebStorage.write(_storageKey, mode.name);
  }

  void toggleTheme(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    _persist(value);
  }

  void setMode(ThemeMode mode) {
    value = mode;
    _persist(value);
  }
}

final themeNotifier = ThemeNotifier();
