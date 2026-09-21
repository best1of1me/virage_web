import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../responsive_layout.dart';
import '../constants/app_info.dart';

/// صفحة عامة (بدون تسجيل دخول) مخصصة للمترشحين لعرض تطبيق الهاتف.
class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  static const String _endpoint = String.fromEnvironment(
    'UPDATE_ENDPOINT',
    defaultValue: 'https://virage.app/api/latest',
  );

  String? _versionName;
  String? _downloadUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _versionName = data['versionName']?.toString();
        _downloadUrl = data['url']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _AppNavBar(),
            _AppHeroSection(
              loading: _loading,
              versionName: _versionName,
              downloadUrl: _downloadUrl,
            ),
            const _AppFeaturesSection(),
            const _ScreenshotsSection(),
            const _ActivationStepsSection(),
            _AppCtaSection(
              loading: _loading,
              versionName: _versionName,
              downloadUrl: _downloadUrl,
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _AppNavBar extends StatelessWidget {
  const _AppNavBar();

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Virage',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (!isMobile)
            Row(
              children: [
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    'الرئيسية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    'مسار مدارس السياقة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.menu_rounded, color: colorScheme.primary),
              tooltip: 'القائمة',
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                context.go('/');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'home', child: Text('الرئيسية')),
                PopupMenuItem(
                  value: 'schools',
                  child: Text('مسار مدارس السياقة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AppHeroSection extends StatelessWidget {
  final bool loading;
  final String? versionName;
  final String? downloadUrl;

  const _AppHeroSection({
    required this.loading,
    required this.versionName,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '📱 مخصص للمترشحين',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'تطبيق Virage\nاجتاز الامتحان النظري بثقة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'تطبيق عربي كامل يعمل بدون إنترنت بعد التفعيل: أكثر من 100 إشارة مرورية مصوّرة، محاكي أسبقيات، وأسئلة الامتحان الشفهي والنظري.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 36),
          _DownloadButton(
            loading: loading,
            versionName: versionName,
            downloadUrl: downloadUrl,
          ),
          const SizedBox(height: 12),
          Text(
            versionName == null ? '' : 'يرجى قراءة خطوات التثبيت في الأسفل',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 12 : 24,
            runSpacing: 8,
            children: const [
              _TrustBadge(text: 'يعمل بدون إنترنت'),
              _TrustBadge(text: 'عربي بالكامل'),
              _TrustBadge(text: 'أندرويد فقط'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppFeaturesSection extends StatelessWidget {
  const _AppFeaturesSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'ماذا ستجد داخل التطبيق؟',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _AppFeatureCard(
                icon: Icons.traffic_rounded,
                title: 'موسوعة الإشارات',
                description:
                    'أكثر من 100 إشارة مرورية مصوّرة مع شرحها واختبارات مخصصة لكل قسم.',
              ),
              _AppFeatureCard(
                icon: Icons.alt_route_rounded,
                title: 'محاكي الأسبقيات',
                description:
                    'خريطة تقاطعات تفاعلية لترتيب أسبقية العبور بأسلوب سحب وإفلات ممتع.',
              ),
              _AppFeatureCard(
                icon: Icons.quiz_rounded,
                title: 'أسئلة الامتحان',
                description:
                    '50 سؤالاً شفهياً و31 سؤالاً نظرياً مع الإجابة الصحيحة وشرح وافٍ.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AppFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  قسم لقطات الشاشة (المحتوى المرئي الأساسي لهذه الصفحة)
// ===========================================================================

class _AppScreenshot {
  final String path;
  final String title;
  final String description;

  const _AppScreenshot({
    required this.path,
    required this.title,
    required this.description,
  });
}

const List<_AppScreenshot> _screens = [
  _AppScreenshot(
    path: 'assets/screenshots/01_learn_signs.jpg',
    title: 'تعلّم الإشارات',
    description:
        'موسوعة مصوّرة لأكثر من 100 إشارة مرورية، مع شرح مفصّل لكل إشارة واختبارات مخصصة لكل قسم.',
  ),
  _AppScreenshot(
    path: 'assets/screenshots/02_priorities.jpg',
    title: 'أولويات المرور',
    description:
        'محاكي تقاطعات تفاعلي: رتّب أسبقية العبور في الحالات المعقدة بسحب وإفلات ممتع.',
  ),
  _AppScreenshot(
    path: 'assets/screenshots/03_oral.jpg',
    title: 'الأسئلة الشفهية',
    description:
        '50 سؤالاً مقسّماً على 5 سلاسل مطابقة لامتحان السياقة الشفهي، مع التصحيح والشرح.',
  ),
  _AppScreenshot(
    path: 'assets/screenshots/04_theory.jpg',
    title: 'الأسئلة النظرية',
    description:
        '31 سؤالاً نظرياً شاملاً مع الإجابة الصحيحة وشرح وافٍ لكل سؤال.',
  ),
  _AppScreenshot(
    path: 'assets/screenshots/05_rewards.jpg',
    title: 'المكافآت والنقاط',
    description:
        'اكسب النقاط يومياً وعند الإجابة الصحيحة لتفتح بها السلاسل والمستويات الجديدة.',
  ),
  _AppScreenshot(
    path: 'assets/screenshots/06_home.jpg',
    title: 'لوحة المتابعة',
    description:
        'تابع تقدمك ونتائج اختباراتك ونقاطك في مكان واحد بسيط وأنيق.',
  ),
];

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'تعرّف على التطبيق من الداخل',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'استكشف الشاشات الأساسية التي سترافقك حتى يوم الامتحان',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 30,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              for (final screenshot in _screens)
                _ScreenshotCard(screenshot: screenshot),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  final _AppScreenshot screenshot;

  const _ScreenshotCard({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 250,
      child: Column(
        children: [
          // إطار هاتف يحمل لقطة الشاشة
          Container(
            width: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // الشريط العلوي للهاتف
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 9 / 18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      screenshot.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        color: colorScheme.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_back_rounded,
                              size: 34,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'لقطة قريباً',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            screenshot.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            screenshot.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  خطوات التفعيل + النداء الأخير للتحميل
// ===========================================================================

class _ActivationStepsSection extends StatelessWidget {
  const _ActivationStepsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Text(
            'كيف أبدأ؟',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _AppStepCard(
                number: '1',
                title: 'حمّل التطبيق',
                description:
                    'اضغط على زر التحميل بالأعلى أو بالأسفل، وانتظر اكتمال تنزيل ملف APK.',
              ),
              _AppStepCard(
                number: '2',
                title: 'ثبّت الملف',
                description:
                    'افتح الملف من مجلد «التنزيلات» واسمح بالتثبيت من «مصادر غير معروفة».',
              ),
              _AppStepCard(
                number: '3',
                title: 'أدخل كود التفعيل',
                description:
                    'استلم كود التفعيل من مدرسة السياقة الخاصة بك وأدخله مرة واحدة فقط.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppStepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _AppStepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCtaSection extends StatelessWidget {
  final bool loading;
  final String? versionName;
  final String? downloadUrl;

  const _AppCtaSection({
    required this.loading,
    required this.versionName,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Text(
            'جاهز للانطلاق؟',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'حمّل التطبيق الآن واستلم من مدرستك كود التفعيل.',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          _DownloadButton(
            loading: loading,
            versionName: versionName,
            downloadUrl: downloadUrl,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  عناصر مشتركة
// ===========================================================================

class _DownloadButton extends StatelessWidget {
  final bool loading;
  final String? versionName;
  final String? downloadUrl;

  const _DownloadButton({
    required this.loading,
    required this.versionName,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: (downloadUrl == null)
          ? null
          : () => web.window.open(downloadUrl!, '_blank'),
      icon: const Icon(Icons.download_rounded),
      label: Text(
        loading
            ? 'جارٍ التحقق من آخر إصدار...'
            : versionName != null
                ? 'تحميل التطبيق (الإصدار ${versionName!})'
                : 'تحميل التطبيق (APK)',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String text;
  const _TrustBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Virage Platform',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppInfo.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار ${AppInfo.version}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}