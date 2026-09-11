import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

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
              leading: const Icon(Icons.description_outlined),
              title: const Text('Plantilla Marketplace'),
              subtitle: const Text(
                'Título y cuerpo con placeholders {{nombre}}, {{precio}}…',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/plantilla'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Datos de empresa'),
              subtitle: const Text(
                'Nombre, ubicación, croquis, horarios (defaults de plantilla)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/empresa'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Ajustes de modelos IA'),
              subtitle: const Text(
                'API externa: imagen, multimodal y quitar fondo',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/ajustes-ia'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nota: la app solo genera borradores locales con plantilla '
            'configurable. No publica a Facebook ni usa Meta Graph API. '
            'Copia el texto y pégalo en Marketplace u otro canal.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
