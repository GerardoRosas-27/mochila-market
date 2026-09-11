import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../meta/presentation/meta_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final meta = ref.watch(metaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta'),
        actions: [
          IconButton(
            tooltip: 'Ajustes IA',
            icon: const Icon(Icons.settings_suggest),
            onPressed: () => context.push('/ajustes-ia'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.isAuthenticated
                        ? 'Sesión local activa'
                        : 'Sin sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (auth.isAuthenticated) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        auth.displayName.isEmpty
                            ? auth.username
                            : auth.displayName,
                      ),
                      subtitle: Text(
                        'Usuario: ${auth.username}\n'
                        'Acceso local · contraseña con hash bcrypt',
                      ),
                      isThreeLine: true,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Meta Graph API'),
              subtitle: Text(
                meta.connectionOk
                    ? 'Conexión OK · Page ${meta.pageId.isEmpty ? "(sin ID)" : meta.pageId}'
                    : 'Configurar App ID, token, Page ID',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/meta'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Datos de empresa'),
              subtitle: const Text('Nombre, ubicación, croquis, horarios'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/empresa'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Ajustes de modelos IA'),
              subtitle: const Text('API de imagen, multimodal y remove.bg'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/ajustes-ia'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nota: no se usa scraping de Meta. Las publicaciones son '
            'borradores locales o posts en feed de Página vía Graph API. '
            'Los ítems de Facebook Marketplace no están disponibles en la '
            'API pública.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
