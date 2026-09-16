import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../responsive_layout.dart';
import '../widgets/page_content.dart';
import '../widgets/dashboard/metrics_grid.dart';
import '../widgets/dashboard/customer_form.dart';
import '../widgets/dashboard/customers_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _purchaseSectionKey = GlobalKey();
  final _metricsKey = GlobalKey<MetricsGridState>();
  bool _isReferralLoading = true;
  bool _hasReferralDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadReferralStatus();
  }

  Future<void> _loadReferralStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isReferralLoading = false);
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('referred_by')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _hasReferralDiscount = profile?['referred_by'] != null;
          _isReferralLoading = false;
        });
      }
    } catch (error) {
      debugPrint('تعذر تحميل حالة خصم الإحالة: $error');
      if (mounted) setState(() => _isReferralLoading = false);
    }
  }

  void _handleReferralAction(BuildContext context) {
    context.go('/referral');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // جلب ID المستخدم المسجل حالياً من Supabase Auth
    final currentUser = Supabase.instance.client.auth.currentUser;
    final String schoolId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageContent(
        maxWidth: 1150,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Welcome Banner Header ---
              Container(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.greenAccent,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'النظام نشط ويعمل بنجاح',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'أهلاً بك في لوحة تحكم Virage 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'تابع أداء ومشتريات الأكواد الخاصة بمدرستك بكل سهولة وفاعلية.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_isReferralLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (!_hasReferralDiscount)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _handleReferralAction(context),
                          icon: const Icon(
                            Icons.card_giftcard_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'احصل على خصم 10% 🎁',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- Metrics Section Header ---
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ملخص المؤشرات والإحصائيات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'تحديث المؤشرات',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () => _metricsKey.currentState?.refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Metrics Grid ---
              MetricsGrid(key: _metricsKey, schoolId: schoolId),

              const SizedBox(height: 28),

              // --- Tables & Forms Grid ---
              KeyedSubtree(
                key: _purchaseSectionKey,
                child: ResponsiveLayout(
                  mobile: Column(
                    children: [
                      const CustomerForm(),
                      const SizedBox(height: 20),
                      CustomersData(schoolId: schoolId),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: CustomersData(schoolId: schoolId),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(flex: 3, child: CustomerForm()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
