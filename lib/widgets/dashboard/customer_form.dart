import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/ui.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  int _selectedPackageCount = 10;
  final double _pricePerCode = 200.0;
  final List<int> _packages = [5, 10, 25, 50, 100];
  bool _isLoading = false;
  bool _hasReferralDiscount = false;

  @override
  void initState() {
    super.initState();
    _checkReferralDiscount();
  }

  Future<void> _checkReferralDiscount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('referred_by')
          .eq('id', userId)
          .maybeSingle();

      bool hasDiscount = false;

      // المدرسة الجديدة (المُحالة): تحصل على خصم 10% على أول عملية شراء فقط
      if (profile != null && profile['referred_by'] != null) {
        final existingCodes = await Supabase.instance.client
            .from('activation_codes')
            .select('id')
            .eq('school_id', userId)
            .limit(1);

        // الخصم متاح إذا كانت أول عملية شراء للمدرسة
        if (existingCodes.isEmpty) {
          hasDiscount = true;
        }
      }

      if (mounted) {
        setState(() => _hasReferralDiscount = hasDiscount);
      }
    } catch (_) {}
  }

  Future<void> _handlePayment(BuildContext context) async {
    setState(() => _isLoading = true);

    final rawTotal = _selectedPackageCount * _pricePerCode;

    final url = Uri.parse(
      'https://virage-backend.onrender.com/api/create-checkout',
    );

    // جلب معرف المستعمل/المدرسة الحالي من Supabase
    final String? schoolId = Supabase.instance.client.auth.currentUser?.id;

    if (schoolId == null) {
      AppSnackbar.error(
        context,
        'لم يتم التعرف على حساب المدرسة، يرجى إعادة التسجيل',
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'school_id': schoolId,
          'count': _selectedPackageCount,
          'amount': rawTotal,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['checkout_url'];

        if (checkoutUrl != null) {
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw 'تعذر فتح رابط الدفع: $checkoutUrl';
          }
        }
      } else if (context.mounted) {
        AppSnackbar.error(context, 'فشل إنشاء طلب الدفع، حاول مرة أخرى');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'خطأ في الاتصال بالخادم');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rawTotal = _selectedPackageCount * _pricePerCode;
    final discountAmount = _hasReferralDiscount ? (rawTotal * 0.10) : 0.0;
    final finalTotal = rawTotal - discountAmount;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_shopping_cart_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'شراء أكواد جديدة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            if (_hasReferralDiscount) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مكافأة الإحالة: خصم 10% مفعّل على أول عملية شراء لك عبر Chargily! 🎁',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.amber.shade300
                              : Colors.brown.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'اختر الباقة المناسبة لمدرستك:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _packages.map((count) {
                final isSelected = count == _selectedPackageCount;
                return ChoiceChip(
                  label: Text('$count أكواد'),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  backgroundColor: isDark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : (isDark
                                ? colorScheme.outline.withValues(alpha: 0.2)
                                : Colors.grey.shade300),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPackageCount = count);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سعر الكود الواحد:',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${_pricePerCode.toStringAsFixed(0)} د.ج',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_hasReferralDiscount) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.0),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المبلغ الأصلي:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${rawTotal.toStringAsFixed(0)} د.ج',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'خصم الإحالة (10%):',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '- ${discountAmount.toStringAsFixed(0)} د.ج',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السعر الإجمالي النهائي:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${finalTotal.toStringAsFixed(0)} د.ج',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : () => _handlePayment(context),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isLoading
                      ? 'جاري توجيهك لبوابة الدفع...'
                      : 'متابعة تأكيد الشراء',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
