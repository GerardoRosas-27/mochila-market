import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/ai_settings/presentation/ai_settings_screen.dart';
import '../../features/auth/presentation/auth_gate_screen.dart';
import '../../core/models/local_user.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/company/presentation/company_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/storefront/presentation/offer_detail_screen.dart';
import '../../features/storefront/presentation/product_detail_screen.dart';
import '../../features/storefront/presentation/storefront_screen.dart';
import '../../features/template/presentation/template_settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

bool _isPublicPath(String loc) {
  if (loc == '/tienda' || loc == '/login') return true;
  if (loc.startsWith('/producto/')) return true;
  if (loc.startsWith('/p/')) return true;
  if (loc.startsWith('/oferta/')) return true;
  return false;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/tienda',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.loading) return null;
      final loc = state.matchedLocation;
      final public = _isPublicPath(loc);
      final onLogin = loc == '/login';

      if (!auth.isAuthenticated) {
        if (public) return null;
        return '/login';
      }
      if (onLogin) return '/publicaciones';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthGateScreen(),
      ),
      // —— Rutas públicas (sin login) ——
      GoRoute(
        path: '/tienda',
        name: 'tienda',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const StorefrontScreen(),
      ),
      GoRoute(
        path: '/producto/:id',
        name: 'producto',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/p/:slug',
        name: 'oferta',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => OfferDetailScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/oferta/:slug',
        redirect: (context, state) => '/p/${state.pathParameters['slug']}',
      ),
      // —— Shell admin (requiere auth) ——
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
                path: '/publicaciones',
                name: 'publicaciones',
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
        path: '/plantilla',
        name: 'plantilla',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const TemplateSettingsScreen(),
      ),
      GoRoute(
        path: '/empresa',
        name: 'empresa',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(path: '/marketplace', redirect: (_, __) => '/publicaciones'),
      GoRoute(path: '/catalogo', redirect: (_, __) => '/inventario'),
      GoRoute(path: '/meta', redirect: (_, __) => '/cuenta'),
      GoRoute(path: '/', redirect: (_, __) => '/tienda'),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
