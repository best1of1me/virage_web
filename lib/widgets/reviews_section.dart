import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// قسم التعليقات والتقييمات — يظهر في صفحة التطبيق العامة `/app`.
/// التقييمات تُحفظ في جدول `site_reviews` عبر Supabase.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _SiteReview {
  final String name;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const _SiteReview({
    required this.name,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory _SiteReview.fromJson(Map<String, dynamic> json) => _SiteReview(
    name: json['name']?.toString() ?? 'زائر',
    rating: int.tryParse(json['rating']?.toString() ?? '') ?? 5,
    comment: json['comment']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  List<_SiteReview> _reviews = [];
  bool _loading = true;
  bool _error = false;
  bool _submitting = false;
  int _myRating = 5;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final response = await Supabase.instance.client
          .from('site_reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response)
            .map(_SiteReview.fromJson)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.from('site_reviews').insert({
        'name': _nameCtrl.text.trim().isEmpty ? 'زائر' : _nameCtrl.text.trim(),
        'rating': _myRating,
        'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شكراً لمشاركتك، تم نشر تقييمك بنجاح.')),
      );
      _nameCtrl.clear();
      _commentCtrl.clear();
      await _fetch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر إرسال التقييم، حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
            'التعليقات والتقييمات',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'آراء المترشحين عن تجربتهم مع التطبيق، وشاركنا رأيك أنت أيضاً',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error
                    ? _ErrorState(onRetry: _fetch)
                    : Column(
                        children: [
                          _RatingSummary(
                            average: _averageRating,
                            count: _reviews.length,
                          ),
                          const SizedBox(height: 32),
                          _ReviewForm(
                            formKey: _formKey,
                            nameCtrl: _nameCtrl,
                            commentCtrl: _commentCtrl,
                            rating: _myRating,
                            submitting: _submitting,
                            onRatingChanged: (value) =>
                                setState(() => _myRating = value),
                            onSubmit: _submit,
                          ),
                          const SizedBox(height: 40),
                          if (_reviews.isNotEmpty) ...[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'أحدث التقييمات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final review in _reviews)
                              _ReviewCard(review: review),
                          ] else
                            Text(
                              'لا توجد تقييمات بعد — كن أول من يشارك رأيه!',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  const _StarRow({
    required this.value,
    this.size = 28,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          onChanged != null
              ? IconButton(
                  tooltip: '$i',
                  onPressed: () => onChanged!(i),
                  icon: Icon(
                    i <= value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= value
                        ? const Color(0xFFF59E0B)
                        : Colors.grey.shade400,
                    size: size,
                  ),
                )
              : Icon(
                  i <= value
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i <= value
                      ? const Color(0xFFF59E0B)
                      : Colors.grey.shade400,
                  size: size,
                ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;

  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                average == 0 ? '—' : average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRow(
                    value: average.round(),
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 0 ? 'لا توجد تقييمات بعد' : 'بناءً على $count تقييم',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController commentCtrl;
  final int rating;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewForm({
    required this.formKey,
    required this.nameCtrl,
    required this.commentCtrl,
    required this.rating,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'شارك تجربتك',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسمك (اختياري)',
                prefixIcon: Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تقييمك',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            _StarRow(value: rating, onChanged: onRatingChanged),
            const SizedBox(height: 16),
            TextFormField(
              controller: commentCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'تقييمك أو ملاحظتك',
                hintText: 'ما رأيك في التطبيق؟',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'اكتب تقييمك قبل الإرسال';
                if (text.length < 2) return 'التقييم قصير جداً';
                return null;
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  submitting ? 'جارٍ الإرسال…' : 'نشر التقييم',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _SiteReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  review.name.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _date(review.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              _StarRow(value: review.rating, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: colorScheme.error),
          const SizedBox(height: 12),
          Text(
            'تعذّر تحميل التقييمات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تأكد من اتصالك بالإنترنت ثم أعد المحاولة',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}