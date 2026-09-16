import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MetricsGrid extends StatefulWidget {
  final String schoolId;

  const MetricsGrid({super.key, required this.schoolId});

  @override
  State<MetricsGrid> createState() => MetricsGridState();
}

class MetricsGridState extends State<MetricsGrid> {
  int _availableCodes = 0;
  int _usedCodes = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  /// إعادة جلب المؤشرات من الخادم (تُستخدم من زر التحديث).
  void refresh() => _fetchMetrics();

  Future<void> _fetchMetrics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final supabase = Supabase.instance.client;

      final availableRes = await supabase
          .from('activation_codes')
          .count(CountOption.exact)
          .eq('school_id', widget.schoolId)
          .eq('status', 'unused');

      final usedRes = await supabase
          .from('activation_codes')
          .count(CountOption.exact)
          .eq('school_id', widget.schoolId)
          .eq('status', 'activated');

      if (mounted) {
        setState(() {
          _availableCodes = availableRes;
          _usedCodes = usedRes;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCodes = _availableCodes + _usedCodes;
    final totalAmount = totalCodes * 200; // 200 د.ج لكل كود كمثال

    if (_isLoading) {
      return const _MetricsLoadingState();
    }

    if (_hasError) {
      return _MetricsErrorState(onRetry: _fetchMetrics);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width < 550 ? 2 : (width < 900 ? 2 : 4);
        final double childAspectRatio = width < 480
            ? 1.15
            : (width < 650 ? 1.4 : (width < 900 ? 1.7 : 1.45));

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _MetricCard(
              title: 'الأكواد المتاحة',
              value: '$_availableCodes',
              trend: 'جاهز للاستخدام',
              icon: Icons.vpn_key_rounded,
              color: const Color(0xFF10B981),
            ),
            _MetricCard(
              title: 'الأكواد المستعملة',
              value: '$_usedCodes',
              trend: 'مفعلة للطلاب',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _MetricCard(
              title: 'القيمة المقدرة',
              value: '$totalAmount د.ج',
              trend: 'محدث الآن',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _MetricCard(
              title: 'إجمالي الأكواد',
              value: '$totalCodes',
              trend: 'الكمية الشاملة',
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );
  }
}

class _MetricsLoadingState extends StatelessWidget {
  const _MetricsLoadingState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 550 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth < 550 ? 1.15 : 1.45,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricsErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _MetricsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          const Text('تعذر تحميل ملخص المؤشرات حالياً'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.5)
                : (isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : const Color(0xFF10B981).withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.03),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  widget.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.trend,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
