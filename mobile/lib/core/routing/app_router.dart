import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentations/attendance_screen.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentations/auth_screen.dart';
import '../../features/booth/presentations/booth_screen.dart';
import '../../features/dashboard/presentations/dashboard_screen.dart';
import '../../features/history/presentations/history_screen.dart';
import '../../features/settings/presentations/settings_screen.dart';
import '../config/bootstrap.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final ready = ref.watch(bootstrapProvider).ready;
  final refresh = _RouterRefresh();
  if (ready) ref.listen(authSessionProvider, (_, next) => refresh.refresh());
  final router = GoRouter(
    initialLocation: AppRoutes.today,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.settings) return null;
      if (!ready) return location == AppRoutes.auth ? null : AppRoutes.auth;
      final session = ref.read(authSessionProvider);
      if (session.isLoading) {
        return location == AppRoutes.loading ? null : AppRoutes.loading;
      }
      if (session.valueOrNull == null) {
        return location == AppRoutes.auth ? null : AppRoutes.auth;
      }
      if (location == AppRoutes.auth || location == AppRoutes.loading) {
        return AppRoutes.today;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.auth, builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: AppRoutes.loading,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          index: state.matchedLocation == AppRoutes.history ? 1 : 0,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) => const HistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (_, _) => const AttendanceScreen(),
      ),
      GoRoute(path: AppRoutes.booth, builder: (_, _) => const BoothScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
