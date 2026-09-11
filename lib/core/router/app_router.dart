import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/ai_settings/presentation/ai_settings_screen.dart';
import '../../features/auth/presentation/auth_gate_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../core/models/local_user.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/company/presentation/company_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/meta/presentation/meta_settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/fotos',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      if (!auth.isAuthenticated) {
        return onLogin ? null : '/login';
      }
      if (onLogin) return '/fotos';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthGateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/fotos',
                name: 'fotos',
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/marketplace',
                name: 'marketplace',
                builder: (context, state) => const MarketplaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventario',
                name: 'inventario',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                name: 'inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cuenta',
                name: 'cuenta',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ajustes-ia',
        name: 'ajustes-ia',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AiSettingsScreen(),
      ),
      GoRoute(
        path: '/meta',
        name: 'meta',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const MetaSettingsScreen(),
      ),
      GoRoute(
        path: '/empresa',
        name: 'empresa',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(
        path: '/catalogo',
        redirect: (_, __) => '/inventario',
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
