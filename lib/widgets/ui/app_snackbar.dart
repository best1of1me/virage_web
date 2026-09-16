import 'package:flutter/material.dart';

/// واجهة موحّدة لإظهار الرسائل في كامل التطبيق بأسلوب احترافي ومتسق.
///
/// مزوّدَة بأنواع رسائل مختلفة (نجاح، خطأ، تحذير، معلومات) مع أيقونات وألوان
/// مناسبة لكل حالة، وتستخدم نمط SnackBar العائم (Floating) بشكل موحّد.
class AppSnackbar {
  const AppSnackbar._();

  /// رسالة نجاح خضراء مع أيقونة صح.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF16A34A),
    );
  }

  /// رسالة خطأ حمراء مع أيقونة تنبيه.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: const Color(0xFFDC2626),
    );
  }

  /// رسالة تحذير برتقالية مع أيقونة تنبيه.
  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFEA8602),
    );
  }

  /// رسالة معلوماتية زرقاء مع أيقونة معلومة.
  static void info(BuildContext context, String message) {
    final color = Theme.of(context).colorScheme.primary;
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: color,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
