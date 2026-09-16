import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// عنصر ملاحة موحد لتجنب تكرار بيانات التنقل في الشريط الجانبي والدرج.
class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      path: '/dashboard',
      label: 'الرئيسية',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _NavItem(
      path: '/profile',
      label: 'الملف الشخصي',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
    _NavItem(
      path: '/contact',
      label: 'تواصل معنا',
      icon: Icons.contact_support_outlined,
      activeIcon: Icons.contact_support_rounded,
    ),
    _NavItem(
      path: '/analytics',
      label: 'التقارير والإحصائيات',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _NavItem(
      path: '/referral',
      label: 'نظام الإحالة',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
    ),
    _NavItem(
      path: '/settings',
      label: 'الإعدادات',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('تأكيد تسجيل الخروج'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من أنك تريد تسجيل الخروج من حسابك؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index >= 0 && index < _navItems.length) {
      context.go(_navItems[index].path);
      return;
    }
    if (index == _navItems.length) {
      _handleSignOut(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: isSmallScreen
            ? AppBar(
                backgroundColor: theme.cardColor,
                elevation: 1,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Virage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, child) {
                      final dark = currentMode == ThemeMode.dark;
                      return IconButton(
                        icon: Icon(
                          dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        tooltip: 'تبديل المظهر',
                        onPressed: () => themeNotifier.toggleTheme(!dark),
                      );
                    },
                  ),
                ],
              )
            : null,
        drawer: isSmallScreen
            ? Drawer(child: _buildNavigationList(context, selectedIndex, true))
            : null,
        body: Row(
          children: [
            if (!isSmallScreen)
              Container(
                width: 220,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Logo Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 24.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Virage',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'لوحة التحكم',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Navigation List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final item in _navItems)
                            _buildNavItem(
                              context: context,
                              index: _navItems.indexOf(item),
                              selectedIndex: selectedIndex,
                              icon: item.icon,
                              activeIcon: item.activeIcon,
                              label: item.label,
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Top Theme Toggle & Quick User Controls
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                )
                              : colorScheme.primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (context, currentMode, child) {
                                final dark = currentMode == ThemeMode.dark;
                                return IconButton(
                                  icon: Icon(
                                    dark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  tooltip: 'تبديل وضع الثيم',
                                  onPressed: () =>
                                      themeNotifier.toggleTheme(!dark),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'تسجيل الخروج',
                              onPressed: () => _handleSignOut(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onItemTapped(index, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationList(
    BuildContext context,
    int selectedIndex,
    bool inDrawer,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Virage',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final item in _navItems)
                ListTile(
                  leading: Icon(item.activeIcon),
                  title: Text(item.label),
                  selected: selectedIndex == _navItems.indexOf(item),
                  selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () {
                    _onItemTapped(_navItems.indexOf(item), context);
                    if (inDrawer) Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            if (inDrawer) Navigator.pop(context);
            _handleSignOut(context);
          },
        ),
      ],
    );
  }
}
