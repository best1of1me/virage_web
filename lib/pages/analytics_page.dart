import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_content.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPeriod = 'هذا الشهر';
  final List<String> _periods = [
    'هذا الأسبوع',
    'هذا الشهر',
    'آخر 3 أشهر',
    'هذه السنة',
  ];

  List<Map<String, dynamic>> _allCodes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'هذا الأسبوع':
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 7));
      case 'هذا الشهر':
        return DateTime(now.year, now.month, 1);
      case 'آخر 3 أشهر':
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 90));
      case 'هذه السنة':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'لم يتم التعرف على المستخدم، يرجى إعادة تسجيل الدخول';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('activation_codes')
          .select('code, status, created_at')
          .eq('school_id', currentUser.id);

      if (mounted) {
        final List<dynamic> dataList = response as List<dynamic>;
        final List<Map<String, dynamic>> loadedCodes = dataList.map((item) {
          final mapItem = item as Map<String, dynamic>;
          final rawStatus = mapItem['status']?.toString() ?? '';
          final createdAt = mapItem['created_at'];

          return {
            'code': mapItem['code']?.toString() ?? '',
            'status': _normalizeStatus(rawStatus),
            'rawDate': createdAt != null
                ? DateTime.tryParse(createdAt.toString())
                : null,
          };
        }).toList();

        setState(() {
          _allCodes = loadedCodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء جلب البيانات: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _normalizeStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'unused' || s == 'متاح' || s == 'active' || s == 'available') {
      return 'متاح';
    } else if (s == 'activated' || s == 'used' || s == 'مستعمل') {
      return 'مستعمل';
    } else if (s == 'expired' || s == 'منتهي') {
      return 'منتهي';
    }
    return status.isNotEmpty ? status : 'متاح';
  }

  List<Map<String, dynamic>> get _filteredCodes {
    final startDate = _getStartDate();
    return _allCodes.where((item) {
      final date = item['rawDate'] as DateTime?;
      if (date == null) return false;
      return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
    }).toList();
  }

  String _calculateAvgUsageDays(List<Map<String, dynamic>> codes) {
    final activatedCodes = codes.where((c) => c['status'] == 'مستعمل').toList();
    if (activatedCodes.isEmpty) return '0';

    final now = DateTime.now();
    double totalDays = 0;
    int validCount = 0;

    for (var code in activatedCodes) {
      final date = code['rawDate'] as DateTime?;
      if (date != null) {
        final diff = now.difference(date).inDays;
        totalDays += diff < 0 ? 0 : diff;
        validCount++;
      }
    }

    if (validCount == 0) return '0';
    return (totalDays / validCount).toStringAsFixed(1);
  }

  List<_WeekData> _calculateWeeklyActivity(List<Map<String, dynamic>> codes) {
    final startDate = _getStartDate();
    final now = DateTime.now();
    final totalDays = now.difference(startDate).inDays;

    // تقسيم الفترة المحددة إلى 4 أجزاء متساوية
    final intervalDays = (totalDays / 4).ceil().clamp(1, 365);
    final weeks = <_WeekData>[];

    for (int i = 0; i < 4; i++) {
      final weekStart = startDate.add(Duration(days: i * intervalDays));
      final weekEnd = (i < 3)
          ? startDate.add(Duration(days: (i + 1) * intervalDays))
          : now.add(const Duration(seconds: 1));

      final count = codes.where((c) {
        final date = c['rawDate'] as DateTime?;
        if (date == null) return false;
        return (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) &&
            date.isBefore(weekEnd);
      }).length;

      weeks.add(_WeekData(label: 'فترة ${i + 1}', count: count));
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.3)
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageContent(
        maxWidth: 1100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(theme, colorScheme, isDark),
              const SizedBox(height: 28),
              if (_isLoading)
                _buildLoadingState(theme)
              else if (_errorMessage != null)
                _buildErrorState(theme, colorScheme)
              else
                _buildDataContent(theme, colorScheme, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.primary.withValues(alpha: 0.45),
                ]
              : [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 18,
            children: [
              SizedBox(
                width: compact ? constraints.maxWidth : 560,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التقارير والإحصائيات',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'راقب أداء الأكواد واتخذ قراراتك بناءً على بيانات واضحة.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderActions(theme, colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: theme.cardColor,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              items: _periods
                  .map(
                    (period) => DropdownMenuItem(
                      value: period,
                      child: Text(
                        period,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedPeriod = value);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          child: IconButton(
            tooltip: 'تحديث البيانات',
            color: Colors.white,
            onPressed: _isLoading ? null : _fetchAnalyticsData,
            icon: _isLoading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الإحصائيات...',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchAnalyticsData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Color borderColor,
  ) {
    final filtered = _filteredCodes;
    final totalCount = filtered.length;
    final availableCount = filtered.where((c) => c['status'] == 'متاح').length;
    final usedCount = filtered.where((c) => c['status'] == 'مستعمل').length;
    final expiredCount = filtered.where((c) => c['status'] == 'منتهي').length;

    final activationRate = totalCount > 0
        ? ((usedCount / totalCount) * 100).round()
        : 0;
    final avgDays = _calculateAvgUsageDays(filtered);
    final weeklyData = _calculateWeeklyActivity(filtered);

    final availablePercent = totalCount > 0
        ? (availableCount / totalCount)
        : 0.0;
    final usedPercent = totalCount > 0 ? (usedCount / totalCount) : 0.0;
    final expiredPercent = totalCount > 0 ? (expiredCount / totalCount) : 0.0;

    final maxWeekCount = weeklyData
        .map((w) => w.count)
        .fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'نظرة عامة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            Text(
              'محدّث حسب الفترة المختارة',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.52),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 1.15 : 1.35,
              children: [
                _buildStatCard(
                  theme: theme,
                  borderColor: borderColor,
                  title: 'معدل التفعيل',
                  value: '$activationRate%',
                  subtitle: '$usedCount من أصل $totalCount كود',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
                _buildStatCard(
                  theme: theme,
                  borderColor: borderColor,
                  title: 'المترشحون النشطون',
                  value: '$usedCount',
                  subtitle: 'كود مفعل حالياً',
                  icon: Icons.groups_rounded,
                  color: colorScheme.primary,
                ),
                _buildStatCard(
                  theme: theme,
                  borderColor: borderColor,
                  title: 'استهلاك الأكواد',
                  value: '$usedCount/$totalCount',
                  subtitle:
                      '$availableCount كود متاح${expiredCount > 0 ? ' • $expiredCount منتهي' : ''}',
                  icon: Icons.confirmation_number_rounded,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  theme: theme,
                  borderColor: borderColor,
                  title: 'متوسط عمر الكود',
                  value: '$avgDays يوم',
                  subtitle: 'متوسط عمر الأكواد المفعلة',
                  icon: Icons.speed_rounded,
                  color: Colors.purple,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 19,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'توزيع الأكواد حسب الحالة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (totalCount == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'لا توجد أكواد في هذه الفترة',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                _buildCategoryRow(
                  theme,
                  'متاح (جاهز للاستخدام)',
                  availablePercent,
                  '${(availablePercent * 100).toStringAsFixed(0)}% ($availableCount كود)',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                _buildCategoryRow(
                  theme,
                  'مستعمل (مفعل)',
                  usedPercent,
                  '${(usedPercent * 100).toStringAsFixed(0)}% ($usedCount كود)',
                  const Color(0xFF3B82F6),
                ),
                if (expiredCount > 0) ...[
                  const SizedBox(height: 16),
                  _buildCategoryRow(
                    theme,
                    'منتهي الصلاحية',
                    expiredPercent,
                    '${(expiredPercent * 100).toStringAsFixed(0)}% ($expiredCount كود)',
                    const Color(0xFFEF4444),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 19,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'نشاط الأكواد حسب الفترة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (maxWeekCount == 0)
                SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'لا يوجد نشاط في هذه الفترة',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyData.map((week) {
                      final heightFactor = maxWeekCount > 0
                          ? week.count / maxWeekCount
                          : 0.0;
                      return _buildBar(
                        theme,
                        week.label,
                        heightFactor,
                        colorScheme.primary,
                        week.count,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required Color borderColor,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.12 : 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    ThemeData theme,
    String label,
    double progress,
    String percentageText,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              percentageText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.08,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(
    ThemeData theme,
    String label,
    double heightFactor,
    Color color,
    int count,
  ) {
    final clampedFactor = heightFactor > 0
        ? heightFactor.clamp(0.05, 1.0)
        : 0.0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: clampedFactor),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedFactor, child) =>
                      FractionallySizedBox(
                        heightFactor: animatedFactor,
                        child: child,
                      ),
                  child: Container(
                    width: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekData {
  final String label;
  final int count;

  _WeekData({required this.label, required this.count});
}
