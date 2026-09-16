import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

/// أدوات آمنة للوصول إلى التخزين المحلي في المتصفح (Web only).
class WebStorage {
  const WebStorage._();

  /// قراءة قيمة مفتاح من localStorage، وترجع null خارج بيئة الويب.
  static String? read(String key) {
    if (!kIsWeb) return null;
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  /// كتابة قيمة في localStorage، وتُتجاهل خارج بيئة الويب.
  static void write(String key, String value) {
    if (!kIsWeb) return;
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {
      // تجاهل أخطاء التخزين عند وجود حظر في بعض المتصفحات
    }
  }

  /// قراءة قيمة منطقية (true/false) أو null حال عدم وجودها.
  static bool? readBool(String key, {bool? defaultValue}) {
    final value = read(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  /// كتابة قيمة منطقية.
  static void writeBool(String key, bool value) => write(key, value.toString());
}
