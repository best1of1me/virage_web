import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/page_content.dart';
import '../widgets/ui/ui.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedSubject = 'استفسار عام';
  bool _isLoading = false;
  bool _isFetchingProfile = true;

  final List<String> _subjects = [
    'استفسار عام',
    'مشكلة في التفعيل والأكواد',
    'دعم تقني في لوحة التحكم',
    'اقتراح ميزة جديدة',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('full_name, school_name, phone_number')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null && mounted) {
          final schoolName = response['school_name'] as String? ?? '';
          final fullName = response['full_name'] as String? ?? '';

          // عرض اسم المدرسة إذا وجد، أو الاسم الكامل
          final displayName = schoolName.isNotEmpty
              ? '$schoolName (${fullName.isNotEmpty ? fullName : ''})'
              : fullName;

          _nameController.text = displayName.trim();
          _phoneController.text = response['phone_number'] ?? '';
        }
      }
    } catch (_) {
      // إهمال الخطأ ومتابعة التحميل
    } finally {
      if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(ColorScheme colorScheme) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('contact_messages').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _selectedSubject,
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        AppSnackbar.success(
          context,
          'تم إرسال رسالتك بنجاح، وسنتواصل معك في أقرب وقت.',
        );
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'حدث خطأ أثناء الإرسال: $e');
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

    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.3)
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageContent(
        maxWidth: 850,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تواصل معنا',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // بطاقات قنوات التواصل السريع
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: _buildInfoCard(
                          theme: theme,
                          colorScheme: colorScheme,
                          borderColor: borderColor,
                          icon: Icons.phone_in_talk_rounded,
                          title: 'الدعم الفني والهاتف',
                          subtitle: 'سوف نتواصل معك في قريب وقت',
                          iconColor: Colors.green,
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? 0 : 16,
                        height: isMobile ? 12 : 0,
                      ),
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: _buildInfoCard(
                          theme: theme,
                          colorScheme: colorScheme,
                          borderColor: borderColor,
                          icon: Icons.email_rounded,
                          title: 'البريد الإلكتروني',
                          subtitle: 'support@virage-app.com',
                          iconColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // نموذج أرسل رسالة
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isFetchingProfile
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إرسال استفسار أو طلب دعم',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // الاسم ورقم الهاتف محملان تلقائياً من الملف الشخصي
                            LayoutBuilder(
                              builder: (context, constraints) {
                                bool isMobile = constraints.maxWidth < 550;
                                return Flex(
                                  direction: isMobile
                                      ? Axis.vertical
                                      : Axis.horizontal,
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: TextFormField(
                                        controller: _nameController,
                                        autofocus: true,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                        validator: (val) =>
                                            val == null || val.trim().isEmpty
                                            ? 'يرجى إدخال الاسم أو تحديث ملفك الشخصي'
                                            : null,
                                        decoration: _buildInputDecoration(
                                          theme: theme,
                                          label: 'الاسم / مدرسة السياقة',
                                          icon: Icons.person_outline_rounded,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: isMobile ? 0 : 16,
                                      height: isMobile ? 16 : 0,
                                    ),
                                    Expanded(
                                      flex: isMobile ? 0 : 1,
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                        validator: (val) {
                                          final phone = val?.trim() ?? '';
                                          if (phone.isEmpty) {
                                            return 'يرجى إدخال رقم الهاتف';
                                          }
                                          final clean = phone.replaceAll(
                                            RegExp(r'[\s\-()]'),
                                            '',
                                          );
                                          if (!RegExp(
                                            r'^(05|06|07)\d{8}$',
                                          ).hasMatch(clean)) {
                                            return 'أدخل رقم هاتف جزائري صحيح';
                                          }
                                          return null;
                                        },
                                        decoration: _buildInputDecoration(
                                          theme: theme,
                                          label: 'رقم الهاتف',
                                          icon: Icons.phone_android_rounded,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // موضوع الرسالة
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSubject,
                              dropdownColor: theme.cardColor,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontFamily: 'Cairo',
                              ),
                              decoration: _buildInputDecoration(
                                theme: theme,
                                label: 'موضوع الرسالة',
                                icon: Icons.subject_rounded,
                                borderColor: borderColor,
                              ),
                              items: _subjects
                                  .map(
                                    (sub) => DropdownMenuItem(
                                      value: sub,
                                      child: Text(sub),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSubject = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // نص الرسالة
                            TextFormField(
                              controller: _messageController,
                              maxLines: 4,
                              maxLength: 2000,
                              style: TextStyle(color: colorScheme.onSurface),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'يرجى كتابة نص الرسالة'
                                  : null,
                              decoration: _buildInputDecoration(
                                theme: theme,
                                label: 'تفاصيل الرسالة أو المشكلة',
                                icon: Icons.chat_bubble_outline_rounded,
                                borderColor: borderColor,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // زر الإرسال
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _sendMessage(colorScheme),
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _isLoading
                                      ? 'جاري الإرسال...'
                                      : 'إرسال الرسالة',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
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

  Widget _buildInfoCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color borderColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color borderColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        size: 20,
      ),
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }
}
