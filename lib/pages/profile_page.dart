import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ui/ui.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isFetchingAddress = false;
  bool _isDirty = false;

  String? _avatarUrl;
  String? _selectedAddress;
  Uint8List? _imageBytes;
  LatLng _selectedLocation = const LatLng(36.7538, 3.0588);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final rawUserId = _supabase.auth.currentUser?.id;
      if (rawUserId == null) return;

      final shortId = rawUserId.substring(0, 6).toUpperCase();
      _userIdController.text = shortId;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', rawUserId)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        _fullNameController.text = data['full_name'] ?? '';
        _phoneController.text = data['phone_number'] ?? '';
        _schoolNameController.text = data['school_name'] ?? '';
        _avatarUrl = data['avatar_url'];

        if (data['latitude'] != null && data['longitude'] != null) {
          _selectedLocation = LatLng(
            (data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble(),
          );
        }
      }

      _fetchAddressForLocation(_selectedLocation);
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تحميل البيانات: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// جلب العنوان النصي المترجم عبر Reverse Geocoding
  Future<void> _fetchAddressForLocation(LatLng location) async {
    if (!mounted) return;
    setState(() => _isFetchingAddress = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=ar',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'virage_app'})
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          setState(() {
            _selectedAddress = data['display_name'];
          });
        }
      }
    } catch (_) {
      // التجاهل عند عدم توفر الاتصال
    } finally {
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  /// البحث عن موقع باسم المدينة أو العنوان أو الإحداثيات
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final coords = _tryParseCoordinates(query);
    if (coords != null) {
      setState(() => _selectedLocation = coords);
      _mapController.move(coords, 15.0);
      _fetchAddressForLocation(coords);
      _showSnackBar('تم الانتقال إلى الإحداثيات المحددة');
      return;
    }

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&accept-language=ar',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'virage_app'})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final newPos = LatLng(lat, lon);

          setState(() => _selectedLocation = newPos);
          _mapController.move(newPos, 14.0);
          _fetchAddressForLocation(newPos);
          _showSnackBar('تم العثور على الموقع وتحديده');
        } else {
          _showSnackBar('لم يتم العثور على المكان المطلوب', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء البحث عن الموقع', isError: true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  LatLng? _tryParseCoordinates(String query) {
    try {
      final parts = query.split(RegExp(r'[,; ]+'));
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lon = double.parse(parts[1].trim());
        if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  /// تحديد موقع المستخدم الحالي بالـ GPS عبر المتصفح
  void _getCurrentLocation() {
    setState(() => _isLocating = true);
    try {
      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition position) {
          final lat = position.coords.latitude;
          final lng = position.coords.longitude;
          if (mounted) {
            final currentPos = LatLng(lat, lng);
            setState(() {
              _selectedLocation = currentPos;
              _isLocating = false;
            });
            _mapController.move(currentPos, 15.0);
            _fetchAddressForLocation(currentPos);
            _showSnackBar('تم تحديد موقعك الحالي بنجاح!');
          }
        }.toJS,
        (web.GeolocationPositionError error) {
          if (mounted) {
            setState(() => _isLocating = false);
            _showSnackBar(
              'تعذر الحصول على موقعك الحالي. يرجى تفعيل الـ GPS بالمتصفح.',
              isError: true,
            );
          }
        }.toJS,
      );
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
      _showSnackBar('تعذر الحصول على موقعك الحالي.', isError: true);
    }
  }

  /// فتح الموقع المحدد مباشرة في خرائط غوغل (Google Maps)
  void _openInGoogleMaps() {
    final lat = _selectedLocation.latitude;
    final lng = _selectedLocation.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    web.window.open(url, '_blank');
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء اختيار الصورة: $e', isError: true);
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageBytes == null) return _avatarUrl;

    final filePath = '$userId/avatar.jpg';
    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          _imageBytes!,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final rawUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
    return '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackbar.warning(
        context,
        'يرجى تصحيح البيانات المحددة بالأحمر قبل الحفظ.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _showSnackBar('المستخدم غير مسجل الدخول', isError: true);
        return;
      }

      final uploadedImageUrl = await _uploadImage(userId);

      final shortId = userId.length >= 6
          ? userId.substring(0, 6).toUpperCase()
          : userId.toUpperCase();
      final updates = {
        'id': userId,
        'referral_code': shortId,
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'school_name': _schoolNameController.text.trim(),
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'avatar_url': uploadedImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').upsert(updates);

      if (mounted) {
        setState(() => _isDirty = false);
        _showSnackBar('تم حفظ البيانات بنجاح!');
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  /// عرض حوار تأكيد عند مغادرة الصفحة مع وجود تعديلات غير محفوظة.
  /// ترجع true إذا وافق المستخدم على التخلي عن التغييرات.
  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!_isDirty) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('تعديلات غير محفوظة'),
          ],
        ),
        content: const Text(
          'لديك تغييرات لم يتم حفظها بعد. هل تريد التخلي عنها؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('متابعة التعديل'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('التخلي عن التغييرات'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(1.0, 18.0),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(1.0, 18.0),
    );
  }

  void _recenterMap() {
    _mapController.move(_selectedLocation, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل البيانات...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 950;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard(context);
        if (leave && mounted) {
          setState(() => _isDirty = false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Banner Section ---
              _buildHeaderBanner(context, theme, colorScheme, isDark),

              const SizedBox(height: 28),

              // --- Main Content Grid / Column ---
              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildFormCard(
                        context,
                        theme,
                        colorScheme,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: _buildMapCard(context, theme, colorScheme, isDark),
                    ),
                  ],
                )
              else ...[
                _buildFormCard(context, theme, colorScheme, isDark),
                const SizedBox(height: 24),
                _buildMapCard(context, theme, colorScheme, isDark),
              ],

              const SizedBox(height: 32),

              // --- Action Save Button Footer ---
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: isWideScreen ? 240 : double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 3,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save_rounded, size: 22),
                    label: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'حفظ التغييرات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الهيدر العلوي الاحترافي بنمط البطاقة المتدرجة
  Widget _buildHeaderBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.surface,
                  colorScheme.surfaceTint.withValues(alpha: 0.15),
                ]
              : [colorScheme.primary, colorScheme.secondary],
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
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: CircleAvatar(
              radius: 90,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: isDark
                            ? colorScheme.surface
                            : Colors.grey[200],
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : (_avatarUrl != null
                                      ? NetworkImage(_avatarUrl!)
                                      : null)
                                  as ImageProvider?,
                        child: (_imageBytes == null && _avatarUrl == null)
                            ? Icon(
                                Icons.storefront_rounded,
                                size: 44,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _schoolNameController.text.isNotEmpty
                            ? _schoolNameController.text
                            : 'اسم مدرسة السياقة',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _fullNameController.text.isNotEmpty
                                ? _fullNameController.text
                                : 'اسم صاحب المدرسة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'حساب مدرسة معتمد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة إدخال البيانات الأساسية
  Widget _buildFormCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
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
                    Icons.badge_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'المعلومات الأساسية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // معرف الحساب
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'معرف الحساب (ID)',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userIdController.text.isNotEmpty
                              ? _userIdController.text
                              : '------',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'نسخ المعرف',
                    onPressed: () {
                      if (_userIdController.text.isNotEmpty) {
                        Clipboard.setData(
                          ClipboardData(text: _userIdController.text),
                        );
                        _showSnackBar('تم نسخ المعرف بنجاح');
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _markDirty(),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'الاسم الكامل مطلوب'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل لصاحب المدرسة',
                      hintText: 'أدخل الاسم الكامل',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => _markDirty(),
                    validator: (val) {
                      final phone = val?.trim() ?? '';
                      if (phone.isEmpty) return 'رقم الهاتف مطلوب';
                      final clean = phone.replaceAll(RegExp(r'[\s\-()]'), '');
                      if (!RegExp(r'^(05|06|07)\d{8}$').hasMatch(clean)) {
                        return 'أدخل رقم هاتف جزائري صحيح (مثال: 06 12 34 56 78)';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      hintText: '06XX XX XX XX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _schoolNameController,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _markDirty(),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'اسم مدرسة السياقة مطلوب'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'اسم مدرسة السياقة',
                      hintText: 'أدخل اسم المؤسسة أو المدرسة',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  /// بطاقة الخريطة والربط بخرائط غوغل
  Widget _buildMapCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Icons.map_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'موقع المدرسة على الخريطة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text(
                    'موقعي الحالي بالـ GPS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    elevation: 1,
                  ),
                  onPressed: _openInGoogleMaps,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    'فتح في Google Maps',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'ابحث باسم المدينة أو أدخل الإحداثيات (lat, lng)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSearching ? null : _searchLocation,
                    child: _isSearching
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 22),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 310,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() => _selectedLocation = point);
                          _fetchAddressForLocation(point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.virage.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 32,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Positioned(
                      top: 12,
                      left: 12,
                      child: Column(
                        children: [
                          _buildMapControlButton(
                            icon: Icons.add_rounded,
                            tooltip: 'تكبير',
                            onPressed: _zoomIn,
                            theme: theme,
                          ),
                          const SizedBox(height: 6),
                          _buildMapControlButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'تصغير',
                            onPressed: _zoomOut,
                            theme: theme,
                          ),
                          const SizedBox(height: 6),
                          _buildMapControlButton(
                            icon: Icons.my_location_rounded,
                            tooltip: 'إعادة التمركز',
                            onPressed: _recenterMap,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isFetchingAddress
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'جاري التعرف على عنوان الموقع...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _selectedAddress ??
                                'انقر على الخريطة أو استخدم البحث لتحديد العنوان',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return Material(
      color: theme.cardColor.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
