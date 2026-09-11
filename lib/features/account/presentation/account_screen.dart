import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/public_base_url.dart';
import '../../auth/presentation/auth_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final baseUrl = ref.watch(publicBaseUrlProvider);
    if (_urlCtrl.text.isEmpty && baseUrl.isNotEmpty) {
      _urlCtrl.text = baseUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta'),
        actions: [
          IconButton(
            tooltip: 'Tienda pública',
            icon: const Icon(Icons.storefront),
            onPressed: () => context.push('/tienda'),
          ),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'URL pública (Railway)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Base para enlaces /p/:slug y /producto/:id que compartes '
                    'en respuestas de Marketplace.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'publicBaseUrl',
                      hintText: 'https://tu-app.up.railway.app',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(publicBaseUrlProvider.notifier)
                          .setUrl(_urlCtrl.text);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL pública guardada')),
                      );
                    },
                    child: const Text('Guardar URL pública'),
                  ),
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
            'Nota: la tienda pública muestra el inventario disponible. '
            'Las publicaciones son grupos de ofertas con URL /p/:slug. '
            'Exportar como borrador solo copia texto para Marketplace; '
            'la app no publica a Facebook.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
