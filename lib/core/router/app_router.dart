import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/ai_settings/presentation/ai_settings_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/fotos',
    routes: [
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
                path: '/catalogo',
                name: 'catalogo',
                builder: (context, state) => const CatalogScreen(),
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
    ],
  );
});
