import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../constants/app_info.dart';
import '../widgets/ui/ui.dart';

/// صفحة الدخول الوحيدة في التطبيق.
///
/// بعد توحيد الموقع لم تبقَ أي صفحة تسويقية داخل Flutter: الصفحة العامة موجودة
/// في `site/index.html`، وهذا التطبيق مخصّص للوحة تحكم مدارس السياقة فقط.
/// من يصل هنا بدون جلسة يرى زر الدخول عبر Google.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busy = false;

  Future<void> _handleGoogleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirectUrl,
      );

      if (response && mounted) {
        context.go('/dashboard');
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, 'خطأ في تسجيل الدخول: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// رابط العودة يُبنى من عنوان الصفحة الحالية حتى يعمل محلياً وعلى الإنتاج.
  String get _oauthRedirectUrl {
    final href = web.window.location.href;
    if (href.isNotEmpty) return '${href.split('#').first}#/dashboard';
    return 'https://best1of1me.github.io/virage_web/app/#/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F4C81), Color(0xFF0B3A63), Color(0xFF1E88E5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCard(theme, colorScheme),
                    const SizedBox(height: 18),
                    Text(
                      AppInfo.copyright,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 74,
            height: 74,
            errorBuilder: (_, _, _) => Icon(
              Icons.qr_code_2_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'VIRAGE',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Color(0xFF0F4C81),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لوحة تحكم مدارس السياقة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'سجّل دخولك بحساب Google الخاص بمدرستك للوصول إلى '
            'أكواد التفعيل وتتبّع المترشحين.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleMark(),
                        SizedBox(width: 10),
                        Text(
                          'الدخول عبر Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'لست مدرسة؟ تطبيق المترشح متوفّر قريباً على Google Play.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// حرف G داخل دائرة بيضاء — بديل خفيف عن شعار Google (دون إضافة حزمة أيقونات).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
