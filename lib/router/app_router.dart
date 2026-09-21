import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/landing_page.dart';
import '../pages/app_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/contact_page.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../pages/analytics_page.dart';
import '../pages/referral_page.dart';
import '../pages/not_found_page.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// انتقال سلس (تلاشي + انزلاق خفيف) بين الصفحات لتجربة استخدام احترافية.
Page<T> _fadeSlidePage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundPage(),
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final path = state.uri.path;
    final isPublicPage = path == '/' || path == '/app';

    if (session == null && !isPublicPage) {
      return '/';
    }

    if (session != null && path == '/') {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeSlidePage(const LandingPage()),
    ),
    GoRoute(
      path: '/app',
      pageBuilder: (context, state) => _fadeSlidePage(const AppPage()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              _fadeSlidePage(const DashboardPage()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _fadeSlidePage(const ProfilePage()),
        ),
        GoRoute(
          path: '/contact',
          pageBuilder: (context, state) => _fadeSlidePage(const ContactPage()),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) =>
              _fadeSlidePage(const AnalyticsPage()),
        ),
        GoRoute(
          path: '/referral',
          pageBuilder: (context, state) => _fadeSlidePage(const ReferralPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _fadeSlidePage(const SettingsPage()),
        ),
      ],
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
