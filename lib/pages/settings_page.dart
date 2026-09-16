import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';
import '../services/web_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = false;
  bool _isResettingPassword = false;

  static const String _notificationsKey = 'virage_notifications_enabled';
  static const String _emailAlertsKey = 'virage_email_alerts_enabled';

  @override
  void initState() {
    super.initState();
    _notificationsEnabled =
        WebStorage.readBool(_notificationsKey, defaultValue: true) ?? true;
    _emailAlertsEnabled =
        WebStorage.readBool(_emailAlertsKey, defaultValue: false) ?? false;
  }

  void _setNotificationsEnabled(bool value) {
    setState(() => _notificationsEnabled = value);
    WebStorage.writeBool(_notificationsKey, value);
  }

  void _setEmailAlertsEnabled(bool value) {
    setState(() => _emailAlertsEnabled = value);
    WebStorage.writeBool(_emailAlertsKey, value);
  }

  Future<void> _resetPassword() async {
    final user = _supabase.auth.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      AppSnackbar.warning(
        context,
        'لا يوجد بريد إلكتروني مرتبط بالحساب الحالي. تم تسجيل الدخول عبر Google.',
      );
      return;
    }

    setState(() => _isResettingPassword = true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        AppSnackbar.success(context, 'تم إرسال رابط التغيير إلى $email بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'تعذر إرسال رابط التغيير: $e');
      }
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('تأكيد تسجيل الخروج'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج من حسابك؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {
        // تجاهل فشل تسجيل الخروج هنا — الموجّه سيعيد التوجيه في كل الأحوال
      }
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header Banner Section ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              colorScheme.surface,
                              colorScheme.surfaceTint.withValues(alpha: 0.12),
                            ]
                          : [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إعدادات المنصة والحساب',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'خصّص مظهر التطبيق، الإشعارات، وتأمين حسابك بسهولة.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 1. قسم المظهر والنظام
                _buildSectionHeader(
                  context,
                  'المظهر والنظام',
                  Icons.palette_outlined,
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, child) {
                      final isDarkMode = currentMode == ThemeMode.dark;
                      return SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'الوضع الداكن (Dark Mode)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'تخصيص ألوان مظهر التطبيق إلى النمط الداكن المريح للعين',
                        ),
                        value: isDarkMode,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        onChanged: (value) {
                          themeNotifier.toggleTheme(value);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 2. قسم الإشعارات والتنبيهات
                _buildSectionHeader(
                  context,
                  'الإشعارات والتنبيهات',
                  Icons.notifications_active_outlined,
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'تفعيل إشعارات المنصة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'استلام تنبيهات المواعيد وتحديثات طلبات الأكواد الجديدة',
                        ),
                        value: _notificationsEnabled,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        onChanged: (value) {
                          _setNotificationsEnabled(value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'التنبيهات عبر البريد الإلكتروني',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'إرسال فواتير الشراء والتقارير الشهرية إلى البريد',
                        ),
                        value: _emailAlertsEnabled,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        onChanged: (value) {
                          _setEmailAlertsEnabled(value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. قسم الحساب والأمان
                _buildSectionHeader(
                  context,
                  'الحساب والأمان',
                  Icons.security_outlined,
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: const Text(
                          'إعادة ضبط كلمة المرور',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'إرسال رابط استعادة كلمة المرور آلياً إلى بريدك المسجل',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: _isResettingPassword ? null : _resetPassword,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'إنهاء الجلسة الحالية والعودة لصفحة الدخول',
                        ),
                        onTap: _signOut,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // معلومات الإصدار والحقوق
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Virage Dashboard System',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الإصدار 1.2.0 • 2026',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
