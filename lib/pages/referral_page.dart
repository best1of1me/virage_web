import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_content.dart';
import '../responsive_layout.dart';
import '../widgets/ui/ui.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _supabase = Supabase.instance.client;
  final _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmittingCode = false;
  bool _hasLoadError = false;
  String? _myReferralCode;
  String? _referredBy;
  String? _referrerSchoolName;

  List<Map<String, dynamic>> _myReferralsList = [];
  int _totalReferrals = 0;
  int _rewardsGranted = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- 1. جلب بيانات الإحالة الخاصة بالمستخدم ---
  Future<void> _loadReferralData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasLoadError = false;
      });
    }
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _hasLoadError = true);
        return;
      }

      final accountId = userId.length >= 6
          ? userId.substring(0, 6).toUpperCase()
          : userId.toUpperCase();
      _myReferralCode = accountId;

      // جلب البروفايل
      final profileRes = await _supabase
          .from('profiles')
          .select('referral_code, referred_by')
          .eq('id', userId)
          .maybeSingle();

      if (profileRes != null) {
        final existingCode = profileRes['referral_code'] as String?;
        _referredBy = profileRes['referred_by'] as String?;

        // حفظ/تحديث كود الإحالة ليكون مساوياً لمعرف الحساب دائماً
        if (existingCode != accountId) {
          await _supabase
              .from('profiles')
              .update({'referral_code': accountId})
              .eq('id', userId);
        }

        // جلب اسم المدرسة التي قامت بإحالته (إن وجد)
        if (_referredBy != null && _referredBy!.isNotEmpty) {
          final referrerRes = await _supabase
              .from('profiles')
              .select('school_name, full_name')
              .eq('id', _referredBy!)
              .maybeSingle();
          if (referrerRes != null) {
            _referrerSchoolName =
                referrerRes['school_name'] ??
                referrerRes['full_name'] ??
                'مدرسة شريكة';
          }
        }
      } else {
        // إنشاء السجل في حال لم يكن موجوداً
        await _supabase.from('profiles').upsert({
          'id': userId,
          'referral_code': accountId,
        });
      }

      // جلب الإحالات الناجحة التي قام بها هذا المستخدم
      final referralsRes = await _supabase
          .from('referrals')
          .select(
            'id, reward_granted, created_at, referred:profiles!referee_id(school_name, full_name, avatar_url)',
          )
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loadedList =
          List<Map<String, dynamic>>.from(referralsRes);

      setState(() {
        _myReferralsList = loadedList;
        _totalReferrals = loadedList.length;
        _rewardsGranted = loadedList
            .where((item) => item['reward_granted'] == true)
            .length;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasLoadError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. إدخال كود إحالة مدرسة أخرى ---
  Future<void> _applyReferralCode() async {
    // 1. فحص صرامة: منع تكرار تفعيل كود إحالة أكثر من مرة للمدرسة نفسها
    if (_referredBy != null && _referredBy!.isNotEmpty) {
      AppSnackbar.warning(
        context,
        'عذراً، لقد قمت بتفعيل كود إحالة سابقاً. لا يمكن استخدام أكثر من كود لكل مدرسة.',
      );
      return;
    }

    final codeInput = _codeController.text.trim().toUpperCase();
    if (codeInput.isEmpty) {
      AppSnackbar.warning(context, 'يرجى إدخال كود الإحالة أولاً');
      return;
    }

    if (codeInput.length != 6) {
      AppSnackbar.warning(
        context,
        'أدخل كود إحالة مكوّناً من 6 أحرف أو أرقام.',
      );
      return;
    }

    // 2. فحص صرامة: منع إحالة النفس
    if (codeInput == _myReferralCode) {
      AppSnackbar.warning(context, 'لا يمكنك استخدام كود الإحالة الخاص بك!');
      return;
    }

    setState(() => _isSubmittingCode = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 3. البحث عن صاحب الكود بـ referral_code
      final referrerProfile = await _supabase
          .from('profiles')
          .select('id, school_name, full_name')
          .eq('referral_code', codeInput)
          .maybeSingle();

      if (referrerProfile == null) {
        if (mounted) {
          AppSnackbar.error(
            context,
            'كود الإحالة (معرف الحساب) غير صحيح أو غير موجود.',
          );
        }
        return;
      }

      final referrerId = referrerProfile['id'] as String;
      final referrerName =
          referrerProfile['school_name'] ??
          referrerProfile['full_name'] ??
          'مدرسة شريكة';

      // 4. فحص صرامة: التأكد من عدم تطابق معرف المستخدم مع صاحب الكود
      if (referrerId == userId) {
        if (mounted) {
          AppSnackbar.warning(context, 'لا يمكنك إحالة نفسك!');
        }
        return;
      }

      // تحديث ملف المستخدم بالحقل referred_by
      await _supabase
          .from('profiles')
          .update({'referred_by': referrerId})
          .eq('id', userId);

      // تسجيل العملية في جدول referrals
      await _supabase.from('referrals').insert({
        'referrer_id': referrerId,
        'referee_id': userId,
        'reward_granted': false,
      });

      _codeController.clear();

      if (mounted) {
        // إظهار حوار الاحتفال بالمكافأة وتوضيح ما تم الحصول عليه
        _showRewardSuccessDialog(context, referrerName: referrerName);
      }
      await _loadReferralData();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'حدث خطأ أثناء تطبيق الكود: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCode = false);
      }
    }
  }

  // --- نافذة احتفالية إعلام المستخدم بالجائزة والمكافأة ---
  void _showRewardSuccessDialog(
    BuildContext context, {
    required String referrerName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'مبروك! تم تفعيل الإحالة 🎉',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم ربط حسابك بنجاح مع $referrerName!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'الجائزة والمكافأة التي حصلت عليها:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• خصم مباشر 10% على أول عملية شراء للأكواد عبر Chargily! 🏷️',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• وسيتم منح المدرسة الداعية 05 أكواد مجانية فور إتمام الدفع بنجاح 🎁',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('رائع، شكرًا!'),
            ),
          ],
        ),
      ),
    );
  }

  // --- نسخ الكود إلى الحافظة ---
  void _copyToClipboard(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    AppSnackbar.success(context, 'تم نسخ كود الإحالة إلى الحافظة بنجاح!');
  }

  void _copyInvitationToClipboard() {
    final code = _myReferralCode;
    if (code == null || code.isEmpty) return;

    Clipboard.setData(
      ClipboardData(
        text:
            'انضم إلى Virage لإدارة أكواد مدرستك بسهولة. استخدم كود الدعوة $code لتحصل على خصم 10% على أول عملية شراء.',
      ),
    );
    AppSnackbar.success(
      context,
      'تم نسخ رسالة الدعوة. يمكنك إرسالها الآن إلى المدرسة المدعوة.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageContent(
        maxWidth: 1150,
        child: RefreshIndicator(
          onRefresh: _loadReferralData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Banner Header ---
                _buildHeaderBanner(theme, colorScheme, isDark),
                const SizedBox(height: 24),

                if (_isLoading)
                  const _ReferralLoadingState()
                else if (_hasLoadError)
                  _buildLoadErrorState(colorScheme)
                else ...[
                  // --- Cards Section ---
                  ResponsiveLayout(
                    mobile: Column(
                      children: [
                        _buildMyCodeCard(theme, colorScheme, isDark),
                        const SizedBox(height: 16),
                        _buildApplyCodeCard(theme, colorScheme, isDark),
                      ],
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildMyCodeCard(theme, colorScheme, isDark),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: _buildApplyCodeCard(
                            theme,
                            colorScheme,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Metrics Cards ---
                  _buildMetricsCards(theme, colorScheme, isDark),
                  const SizedBox(height: 28),

                  // --- Referrals Table Header ---
                  Text(
                    'سجل المدارس المحالة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Referrals Table / Empty List ---
                  _buildReferralsList(theme, colorScheme, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Banner ---
  Widget _buildHeaderBanner(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.surface,
                  colorScheme.surfaceTint.withValues(alpha: 0.12),
                ]
              : [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
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
                        Icons.card_giftcard_rounded,
                        size: 14,
                        color: Colors.amberAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'برنامج مكافآت الإحالة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'برنامج إحالة المدارس والمكافآت 🎁',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• المدرسة الجديدة (المُحالة): تحصل على خصم مباشر 10% على أول عملية شراء أكواد عبر Chargily عند استخدام الكود.\n• المدرسة الداعية (المُحيلة): تحصل على 05 أكواد مجانية تضاف لرصيدها فور إتمام المدرسة الجديدة لعملية الدفع بنجاح!',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 1: My Referral Code ---
  Widget _buildMyCodeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كود الإحالة الخاص بك',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'يمكن لأي مدرسة إدخال هذا الكود عند الانضمام',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Displayer Box for Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    _myReferralCode ?? '---',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _copyToClipboard(_myReferralCode ?? ''),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'نسخ الكود',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyInvitationToClipboard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('نسخ ومشاركة الكود مع المدارس'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card 2: Apply Referral Code ---
  Widget _buildApplyCodeCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هل تمت دعوتك من مدرسة أخرى؟',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'أدخل كود الدعوة للربط والاستفادة من العروض',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_referredBy != null && _referredBy!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تم تفعيل كود الإحالة سابقاً',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'تمت إحالتك بواسطة: ${_referrerSchoolName ?? 'مدرسة شريكة'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // البنر التحفيزي للمستخدمين الجدد
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.amber.shade900.withValues(alpha: 0.4),
                            Colors.amber.shade800.withValues(alpha: 0.2),
                          ]
                        : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade700, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade700.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎁 هدية ترحيبية للمدارس الجديدة!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'أدخل كود المدرسة التي دعتك فوراً للحصول على خصم 10% مباشر على أول طلبية شراء للأكواد عبر Chargily!',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) {
                  if (!_isSubmittingCode) _applyReferralCode();
                },
                decoration: InputDecoration(
                  labelText: 'كود الإحالة / معرف الحساب (مثال: 6F3A2B)',
                  helperText: 'يتكون الكود من 6 أحرف أو أرقام',
                  prefixIcon: const Icon(
                    Icons.vpn_key_rounded,
                    color: Colors.amber,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'خصم 10%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmittingCode ? null : _applyReferralCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmittingCode
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.card_giftcard_rounded, size: 20),
                  label: const Text(
                    'تفعيل كود الإحالة والحصول على الخصم 🎁',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Metrics Cards ---
  Widget _buildMetricsCards(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final metrics = [
      Expanded(
        child: _buildMetricItem(
          theme,
          colorScheme,
          title: 'إجمالي الإحالات',
          value: '$_totalReferrals',
          icon: Icons.people_alt_rounded,
          iconColor: colorScheme.primary,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _buildMetricItem(
          theme,
          colorScheme,
          title: 'المكافآت الممنوحة',
          value: '$_rewardsGranted',
          icon: Icons.workspace_premium_rounded,
          iconColor: Colors.amber,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _buildMetricItem(
          theme,
          colorScheme,
          title: 'قيد الانتظار',
          value: '${_totalReferrals - _rewardsGranted}',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.orange,
        ),
      ),
    ];

    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildMetricItem(
            theme,
            colorScheme,
            title: 'إجمالي الإحالات',
            value: '$_totalReferrals',
            icon: Icons.people_alt_rounded,
            iconColor: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildMetricItem(
            theme,
            colorScheme,
            title: 'المكافآت الممنوحة',
            value: '$_rewardsGranted',
            icon: Icons.workspace_premium_rounded,
            iconColor: Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildMetricItem(
            theme,
            colorScheme,
            title: 'قيد الانتظار',
            value: '${_totalReferrals - _rewardsGranted}',
            icon: Icons.hourglass_top_rounded,
            iconColor: Colors.orange,
          ),
        ],
      ),
      desktop: Row(children: metrics),
    );
  }

  Widget _buildLoadErrorState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            const Text('تعذر تحميل برنامج الإحالة حالياً'),
            const SizedBox(height: 6),
            Text(
              'تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadReferralData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Referrals List Table ---
  Widget _buildReferralsList(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (_myReferralsList.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 54,
                color: colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                'لم يتم تسجيل أي إحالات بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'شارِك كود الإحالة الخاص بك للبدء في دعوة المدارس وجمع المكافآت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _myReferralsList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _myReferralsList[index];
          final referredProfile = item['referred'] as Map<String, dynamic>?;
          final schoolName =
              referredProfile?['school_name'] ??
              referredProfile?['full_name'] ??
              'مدرسة شريكة';
          final bool rewardGranted = item['reward_granted'] ?? false;
          final createdAt = item['created_at'] != null
              ? DateTime.tryParse(item['created_at'].toString())
              : null;
          final formattedDate = createdAt != null
              ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
              : '---';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            title: Text(
              schoolName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            subtitle: Text(
              'تاريخ الانضمام: $formattedDate',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: rewardGranted
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: rewardGranted ? Colors.green : Colors.orange,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    rewardGranted
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: rewardGranted ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rewardGranted ? 'مكافأة ممنوحة' : 'قيد المعالجة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rewardGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReferralLoadingState extends StatelessWidget {
  const _ReferralLoadingState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تجهيز برنامج الإحالة...',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
