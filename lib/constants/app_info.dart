/// ثوابت التطبيق المشتركة (إصدار موحّد يظهر في عدة صفحات).
class AppInfo {
  const AppInfo._();

  /// نسخة التطبيق الحالية — ثابت واحد يجب تحديثه عند كل إصدار.
  static const String version = '1.0.3';

  /// الاسم التجاري للمنصة.
  static const String name = 'Virage';

  /// وصف مختصر يظهر في التذييلات وشاشات العرض.
  static const String tagline = 'منصة أكواد التفعيل لمدارس تعليم السياقة';

  /// حقوق النشر.
  static String get copyright => '© 2026 $name. جميع الحقوق محفوظة.';
}
