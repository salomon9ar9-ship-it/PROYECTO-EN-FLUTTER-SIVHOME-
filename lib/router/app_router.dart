// lib/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/security/security_screen.dart';
import '../screens/intelligence/intelligence_screen.dart';
import '../screens/visualization/visualization_3d_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/zones/zone_detail_screen.dart';
import '../screens/zones/appliance_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (ctx, state) {
      final loggedIn = auth.valueOrNull != null;
      final onAuth   = state.matchedLocation.startsWith('/auth') ||
                       state.matchedLocation == '/splash';
      if (!loggedIn && !onAuth) return '/auth/login';
      if (loggedIn && onAuth && state.matchedLocation != '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/home',          builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/security',      builder: (_, __) => const SecurityScreen()),
          GoRoute(path: '/intelligence',  builder: (_, __) => const IntelligenceScreen()),
          GoRoute(path: '/visualization', builder: (_, __) => const Visualization3DScreen()),
          GoRoute(path: '/alerts',        builder: (_, __) => const AlertsScreen()),
          GoRoute(path: '/reports',       builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
          GoRoute(
            path: '/zones/:id',
            builder: (_, s) => ZoneDetailScreen(zoneId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/appliances/:id',
            builder: (_, s) => ApplianceDetailScreen(appId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
