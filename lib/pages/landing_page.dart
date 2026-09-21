import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../responsive_layout.dart';
import '../widgets/ui/ui.dart';
import '../constants/app_info.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _schoolKey = GlobalKey();

  Future<void> _handleGoogleSignIn() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signInWithOAuth(
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
    }
  }

  /// توليد رابط العودة ديناميكياً بناءً على عنوان الصفحة الحالية (يعمل في الإنتاج).
  String get _oauthRedirectUrl {
    final href = web.window.location.href;
    if (href.isNotEmpty) return '${href.split('#').first}#/dashboard';
    return 'http://localhost:8080/#/dashboard';
  }

  void _scrollToKey(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
            _NavBar(
              onTraineeTap: () => context.go('/app'),
              onSchoolTap: () => _scrollToKey(_schoolKey),
              onLoginTap: _handleGoogleSignIn,
            ),
            _HeroSection(
              onRegisterTap: _handleGoogleSignIn,
              onTraineeTap: () => context.go('/app'),
            ),
            const _StatsBar(),
            // مسار مدرسة السياقة فقط (مسار المترشح في صفحة /app).
            Container(
              key: _schoolKey,
              child: const _SchoolPathSection(),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final VoidCallback onTraineeTap;
  final VoidCallback onSchoolTap;
  final VoidCallback onLoginTap;

  const _NavBar({
    required this.onTraineeTap,
    required this.onSchoolTap,
    required this.onLoginTap,
  });

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
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
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
                  onPressed: onTraineeTap,
                  child: const Text(
                    'المترشحون',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onSchoolTap,
                  child: const Text(
                    'مدارس السياقة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: onLoginTap,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('تسجيل الدخول بـ Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                switch (value) {
                  case 'trainee':
                    onTraineeTap();
                  case 'school':
                    onSchoolTap();
                  case 'login':
                    onLoginTap();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'trainee', child: Text('المترشحون')),
                PopupMenuItem(
                  value: 'school',
                  child: Text('مدارس السياقة'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('تسجيل الدخول بـ Google'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onTraineeTap;

  const _HeroSection({
    required this.onRegisterTap,
    required this.onTraineeTap,
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
          // شعار التطبيق الرسمي
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
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
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
              '🚀 منصة عربية لتعليم السياقة والتحضير للامتحان',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'احترف الطريق\nبينك وبين مدرستك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'تطبيق تعليمي متكامل للمترشح، ولوحة تحكم لمدارس السياقة لتوزيع أكواد التفعيل وتتبع الاستعمال. اختر مسارك في الأسفل.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 44),
          // بطاقتا اختيار المسار
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _PathCard(
                icon: Icons.school_rounded,
                title: 'مترشح',
                description:
                    'اكتشف تطبيق Virage، حمّله، وأدخل كود التفعيل الذي استلمته من مدرستك لتبدأ التحضير للامتحان.',
                buttonLabel: 'اكتشف تطبيق المترشح',
                buttonIcon: Icons.android_rounded,
                isPrimary: false,
                onTap: onTraineeTap,
              ),
              _PathCard(
                icon: Icons.business_center_rounded,
                title: 'مدرسة سياقة',
                description:
                    'سجّل مدرستك مجاناً عبر Google، اشترِ أكواد التفعيل بالجملة بأسعار تفضيلية، ووزّعها وتتبّع استعمالها.',
                buttonLabel: 'سجّل مدرستك عبر Google',
                buttonIcon: Icons.login_rounded,
                isPrimary: true,
                onTap: onRegisterTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 12 : 24,
            runSpacing: 8,
            children: const [
              _TrustBadge(text: 'مجاني للتسجيل'),
              _TrustBadge(text: 'دفع آمن للأكواد'),
              _TrustBadge(text: 'تتبع فوري للاستعمال'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PathCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 340,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: colorScheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          if (isPrimary)
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
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

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: const Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 40,
        runSpacing: 24,
        children: [
          _StatItem(value: '104', label: 'إشارة مرورية'),
          _StatItem(value: '50', label: 'سؤالاً للامتحان الشفهي'),
          _StatItem(value: '31', label: 'سؤالاً للامتحان النظري'),
          _StatItem(value: '5', label: 'سلاسل امتحان شفهي'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
//  المسار الوحيد المتبقي في صفحة الهبوط: مدرسة السياقة
// ===========================================================================

class _SchoolPathSection extends StatelessWidget {
  const _SchoolPathSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 80, bottom: 8),
          child: _SectionHeader(
            icon: Icons.business_center_rounded,
            eyebrow: 'مسار مدرسة السياقة',
            title: 'لوحة تحكم كاملة لبيع الأكواد وتتبع المترشحين',
            subtitle:
                'سجّل مدرستك مجاناً عبر Google، واشترِ أكواد التفعيل بالجملة، ووزّعها على مترشحيك وتابع من فعّل كوده.',
          ),
        ),
        _FeaturesSection(),
        _HowItWorksSection(),
        _PartnershipCta(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                eyebrow,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Text(
            'لماذا تختار لوحة تحكم المدرسة؟',
            style: TextStyle(
              fontSize: 26,
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
              _FeatureCard(
                icon: Icons.shopping_cart_checkout_rounded,
                title: 'شراء الأكواد بالجملة',
                description:
                    'اشترِ أي كمية من أكواد التفعيل مباشرة من لوحة التحكم، بأسعار خاصة للمدارس.',
              ),
              _FeatureCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'توزيع سهل على المترشحين',
                description:
                    'وزّع كل كود على مترشح محدد، وتتبع اسمه ورقم هاتفه المرتبط بالكود المُسلَّم.',
              ),
              _FeatureCard(
                icon: Icons.analytics_rounded,
                title: 'تتبع الاستعمال لحظياً',
                description:
                    'اعرف مباشرة من فعّل كوده، ومن لم يستعمله بعد، لمتابعة مترشحيك عن قرب.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.5)
                : (isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.grey.shade200),
          ),
        ),
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 40, color: colorScheme.primary),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          Text(
            'كيف تعمل المنصة؟',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'من الشراء إلى تتبع أول مترشح يفعّل كوده، في ثلاث خطوات',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _StepCard(
                number: '1',
                icon: Icons.login_rounded,
                title: 'سجل بحساب Google',
                description:
                    'إنشاء حساب مدرستك يستغرق أقل من دقيقة، بدون أي إجراءات معقدة.',
              ),
              _StepCard(
                number: '2',
                icon: Icons.shopping_cart_checkout_rounded,
                title: 'اشترِ أكواد التفعيل',
                description:
                    'حدد عدد الأكواد التي تحتاجها حسب عدد مترشحيك، وأتمم الدفع بأمان.',
              ),
              _StepCard(
                number: '3',
                icon: Icons.fact_check_rounded,
                title: 'وزّع وتتبع الاستعمال',
                description:
                    'سلّم كل كود لمترشح، وتابع من فعّله ومن لم يفعّله بعد من لوحة التحكم.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.icon,
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
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: colorScheme.primary),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardColor, width: 2),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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

class _PartnershipCta extends StatelessWidget {
  const _PartnershipCta();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'برنامج الشراكة والأسعار الخاصة',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'نقدم أسعاراً تفضيلية على الأكواد للمدارس المتعددة الفروع والجمعيات والاتحادات.',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.handshake_rounded, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('طلب شراكة جديدة'),
                      ],
                    ),
                    content: const Text(
                      'شكراً لاهتمامك! سيتم التواصل معك قريباً بواسطة فريق الشراكات للاتفاق على التفاصيل.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('حسنًا'),
                      ),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.handshake_rounded, size: 20),
            label: const Text(
              'قدم طلب الشراكة الآن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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