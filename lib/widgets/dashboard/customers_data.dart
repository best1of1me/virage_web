import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/ui.dart';

class CustomersData extends StatefulWidget {
  final String schoolId;

  const CustomersData({super.key, required this.schoolId});

  @override
  State<CustomersData> createState() => _CustomersDataState();
}

class _CustomersDataState extends State<CustomersData> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'الكل';
  String _sortBy = 'التاريخ (الأحدث)';

  List<Map<String, dynamic>> _allCodes = [];
  final Set<String> _selectedCodes = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _recentlyCopiedCode;

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchCodes();
  }

  Future<void> _fetchCodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('activation_codes')
          .select('code, status, created_at')
          .eq('school_id', widget.schoolId);

      if (mounted) {
        final List<Map<String, dynamic>> loadedCodes = [];
        for (var item in List<Map<String, dynamic>>.from(response)) {
          final rawCode = item['code']?.toString() ?? '';
          final rawStatus = item['status']?.toString() ?? '';
          final createdAt = item['created_at'];

          loadedCodes.add({
            'code': rawCode,
            'status': _normalizeStatus(rawStatus),
            'rawStatus': rawStatus,
            'date': _formatDate(createdAt),
            'rawDate': createdAt != null
                ? DateTime.tryParse(createdAt.toString())
                : null,
          });
        }

        setState(() {
          _allCodes = loadedCodes;
          _isLoading = false;
          _selectedCodes.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحميل الأكواد. تحقق من اتصالك ثم أعد المحاولة.';
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

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'غير متوفر';
    final str = dateVal.toString();
    if (str.contains('T')) {
      return str.split('T').first;
    }
    return str;
  }

  List<Map<String, dynamic>> _getFilteredAndSortedCodes() {
    final query = _searchController.text.trim().toLowerCase();

    var filtered = _allCodes.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item['code'].toString().toLowerCase().contains(query) ||
          item['date'].toString().contains(query);
      final matchesFilter =
          _selectedFilter == 'الكل' || item['status'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortBy == 'التاريخ (الأحدث)') {
        final dateA = a['rawDate'] as DateTime? ?? DateTime(1970);
        final dateB = b['rawDate'] as DateTime? ?? DateTime(1970);
        return dateB.compareTo(dateA);
      } else if (_sortBy == 'التاريخ (الأقدم)') {
        final dateA = a['rawDate'] as DateTime? ?? DateTime(1970);
        final dateB = b['rawDate'] as DateTime? ?? DateTime(1970);
        return dateA.compareTo(dateB);
      } else if (_sortBy == 'الكود') {
        return (a['code'] as String).compareTo(b['code'] as String);
      }
      return 0;
    });

    return filtered;
  }

  // ---- ذاكرة تخزين مؤقت لتجنب إعادة الحساب في كل إعادة بناء ----

  List<Map<String, dynamic>>? _countsAllCodesRef;
  ({int total, int available, int used, int expired})? _cachedCounts;

  ({int total, int available, int used, int expired}) get _statusCounts {
    if (_cachedCounts == null || !identical(_countsAllCodesRef, _allCodes)) {
      _countsAllCodesRef = _allCodes;
      _cachedCounts = (
        total: _allCodes.length,
        available: _allCodes.where((c) => c['status'] == 'متاح').length,
        used: _allCodes.where((c) => c['status'] == 'مستعمل').length,
        expired: _allCodes.where((c) => c['status'] == 'منتهي').length,
      );
    }
    return _cachedCounts!;
  }

  List<Map<String, dynamic>>? _cacheAllCodesRef;
  String _cacheSearchText = '';
  String _cacheFilter = '';
  String _cacheSortBy = '';
  List<Map<String, dynamic>>? _cacheFilteredCodes;

  List<Map<String, dynamic>> _getFilteredCodesCached() {
    final text = _searchController.text;
    if (identical(_cacheAllCodesRef, _allCodes) &&
        _cacheSearchText == text &&
        _cacheFilter == _selectedFilter &&
        _cacheSortBy == _sortBy &&
        _cacheFilteredCodes != null) {
      return _cacheFilteredCodes!;
    }
    _cacheAllCodesRef = _allCodes;
    _cacheSearchText = text;
    _cacheFilter = _selectedFilter;
    _cacheSortBy = _sortBy;
    _cacheFilteredCodes = _getFilteredAndSortedCodes();
    return _cacheFilteredCodes!;
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _recentlyCopiedCode = code);

    AppSnackbar.success(context, 'تم نسخ الكود بنجاح: $code');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _recentlyCopiedCode == code) {
        setState(() => _recentlyCopiedCode = null);
      }
    });
  }

  void _copySelectedCodes() {
    if (_selectedCodes.isEmpty) return;
    final codesText = _selectedCodes.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));

    AppSnackbar.success(context, 'تم نسخ ${_selectedCodes.length} كود بنجاح!');
  }

  void _copyAvailableCodes() {
    final available = _allCodes
        .where((e) => e['status'] == 'متاح')
        .map((e) => e['code'] as String)
        .toList();
    if (available.isEmpty) {
      AppSnackbar.info(context, 'لا توجد أكواد متاحة للنسخ حالياً');
      return;
    }
    Clipboard.setData(ClipboardData(text: available.join('\n')));
    AppSnackbar.success(
      context,
      'تم نسخ جميع الأكواد المتاحة (${available.length} كود)',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filteredCodes = _getFilteredCodesCached();
    final counts = _statusCounts;
    final totalCount = counts.total;
    final availableCount = counts.available;
    final usedCount = counts.used;
    final expiredCount = counts.expired;

    // Pagination bounds
    final totalPages = (filteredCodes.length / _rowsPerPage).ceil();
    final safePage = _currentPage > totalPages
        ? (totalPages > 0 ? totalPages : 1)
        : _currentPage;
    final startIndex = (safePage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage > filteredCodes.length)
        ? filteredCodes.length
        : startIndex + _rowsPerPage;
    final paginatedCodes = filteredCodes.isEmpty
        ? <Map<String, dynamic>>[]
        : filteredCodes.sublist(startIndex, endIndex);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            _buildHeader(context, isDark, colorScheme),

            const SizedBox(height: 16),

            // Statistics Summary Chips
            _buildStatsBar(
              context,
              totalCount: totalCount,
              availableCount: availableCount,
              usedCount: usedCount,
              expiredCount: expiredCount,
            ),

            const SizedBox(height: 20),

            // Search, Filter & Quick Action Row
            _buildFilterRow(context, isDark, colorScheme, filteredCodes.length),

            const SizedBox(height: 16),

            // Selected Batch Actions Bar
            if (_selectedCodes.isNotEmpty)
              _buildBatchActionsBar(context, colorScheme),

            // Content Area
            _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : filteredCodes.isEmpty
                ? _buildEmptyState(context, colorScheme)
                : Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 650) {
                            return _buildMobileListView(
                              context,
                              paginatedCodes,
                            );
                          } else {
                            return _buildDesktopTable(context, paginatedCodes);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pagination Controls
                      if (totalPages > 1)
                        _buildPaginationBar(
                          context,
                          safePage,
                          totalPages,
                          filteredCodes.length,
                          startIndex,
                          endIndex,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل الأكواد المشتراة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'إدارة وعرض حالة أكواد التفعيل الخاصة بالمؤسسة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _copyAvailableCodes,
              icon: const Icon(Icons.content_copy_rounded, size: 16),
              label: const Text('نسخ المتاحة'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'تحديث البيانات',
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _fetchCodes,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsBar(
    BuildContext context, {
    required int totalCount,
    required int availableCount,
    required int usedCount,
    required int expiredCount,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _buildStatChip(
          context,
          label: 'إجمالي الأكواد',
          value: '$totalCount',
          icon: Icons.all_inbox_rounded,
          color: const Color(0xFF6366F1),
          filterKey: 'الكل',
        ),
        _buildStatChip(
          context,
          label: 'متاحة',
          value: '$availableCount',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF10B981),
          filterKey: 'متاح',
        ),
        _buildStatChip(
          context,
          label: 'مستعملة',
          value: '$usedCount',
          icon: Icons.lock_clock_rounded,
          color: const Color(0xFF3B82F6),
          filterKey: 'مستعمل',
        ),
        if (expiredCount > 0)
          _buildStatChip(
            context,
            label: 'منتهية',
            value: '$expiredCount',
            icon: Icons.cancel_outlined,
            color: const Color(0xFFEF4444),
            filterKey: 'منتهي',
          ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String filterKey,
  }) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
          _currentPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    int resultCount,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Input
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن كود أو تاريخ...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _currentPage = 1);
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
            ),
            onChanged: (_) => setState(() => _currentPage = 1),
          ),
        ),

        // Sort By Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.sort_rounded, size: 18),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              items: const [
                DropdownMenuItem(
                  value: 'التاريخ (الأحدث)',
                  child: Text('الأحدث أولاً'),
                ),
                DropdownMenuItem(
                  value: 'التاريخ (الأقدم)',
                  child: Text('الأقدم أولاً'),
                ),
                DropdownMenuItem(value: 'الكود', child: Text('حسب الكود')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _sortBy = val);
              },
            ),
          ),
        ),

        // Rows Per Page Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _rowsPerPage,
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 عناصر')),
                DropdownMenuItem(value: 10, child: Text('10 عناصر')),
                DropdownMenuItem(value: 25, child: Text('25 عنصر')),
                DropdownMenuItem(value: 50, child: Text('50 عنصر')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchActionsBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_box_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تم تحديد ${_selectedCodes.length} كود',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _copySelectedCodes,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('نسخ المحددة'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _selectedCodes.clear()),
                child: const Text('إلغاء التحديد'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<Map<String, dynamic>> codes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSelectedOnPage =
        codes.isNotEmpty &&
        codes.every((c) => _selectedCodes.contains(c['code']));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.outline.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 350 > 500
                  ? MediaQuery.of(context).size.width - 350
                  : 500,
            ),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                colorScheme.primary.withValues(alpha: 0.05),
              ),
              columns: [
                DataColumn(
                  label: Checkbox(
                    value: allSelectedOnPage,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          for (var c in codes) {
                            _selectedCodes.add(c['code']);
                          }
                        } else {
                          for (var c in codes) {
                            _selectedCodes.remove(c['code']);
                          }
                        }
                      });
                    },
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'الكود الرقمي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'تاريخ الشراء',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'الحالة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  numeric: true,
                  label: Text(
                    'الإجراءات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: codes.map((item) {
                final codeStr = item['code'] as String;
                final isSelected = _selectedCodes.contains(codeStr);
                final isRecentlyCopied = _recentlyCopiedCode == codeStr;

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCodes.add(codeStr);
                      } else {
                        _selectedCodes.remove(codeStr);
                      }
                    });
                  },
                  cells: [
                    DataCell(
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCodes.add(codeStr);
                            } else {
                              _selectedCodes.remove(codeStr);
                            }
                          });
                        },
                      ),
                    ),
                    DataCell(
                      SelectableText(
                        codeStr,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.1,
                          color: isRecentlyCopied ? colorScheme.primary : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(item['date'] as String),
                        ],
                      ),
                    ),
                    DataCell(
                      _buildStatusChip(context, item['status'] as String),
                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isRecentlyCopied
                                  ? const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('done'),
                                      color: Colors.green,
                                      size: 18,
                                    )
                                  : Icon(
                                      Icons.copy_rounded,
                                      key: const ValueKey('copy'),
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                            ),
                            tooltip: 'نسخ الكود',
                            onPressed: () => _copyToClipboard(codeStr),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileListView(
    BuildContext context,
    List<Map<String, dynamic>> codes,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: codes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = codes[index];
        final codeStr = item['code'] as String;
        final isSelected = _selectedCodes.contains(codeStr);
        final isRecentlyCopied = _recentlyCopiedCode == codeStr;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCodes.add(codeStr);
                      } else {
                        _selectedCodes.remove(codeStr);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        codeStr,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          letterSpacing: 1.0,
                          color: isRecentlyCopied
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['date'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, item['status'] as String),
                const SizedBox(width: 4),
                IconButton(
                  icon: isRecentlyCopied
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.green,
                          size: 18,
                        )
                      : Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  tooltip: 'نسخ',
                  onPressed: () => _copyToClipboard(codeStr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'متاح':
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        fg = const Color(0xFF047857);
        icon = Icons.check_circle_rounded;
        break;
      case 'مستعمل':
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        fg = const Color(0xFF1D4ED8);
        icon = Icons.lock_clock_rounded;
        break;
      case 'منتهي':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        fg = const Color(0xFFB91C1C);
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade800;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11.5,
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    int currentPage,
    int totalPages,
    int totalItems,
    int startIndex,
    int endIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'عرض ${startIndex + 1} - $endIndex من إجمالي $totalItems كود',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'الصفحة السابقة',
              onPressed: currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$currentPage / $totalPages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'الصفحة التالية',
              onPressed: currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'جاري تحميل البيانات...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchCodes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    final hasFilter =
        _searchController.text.isNotEmpty || _selectedFilter != 'الكل';
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.inbox_rounded,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text(
              hasFilter
                  ? 'لم يتم العثور على أية أكواد مطابقة لخيارات البحث والفلترة'
                  : 'لا تتوفر أية أكواد مشتراة حالياً لهذا الحساب',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedFilter = 'الكل';
                    _currentPage = 1;
                  });
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('إعادة تعيين الفلاتر'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
