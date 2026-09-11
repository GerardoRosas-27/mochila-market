import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'account_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(accountProvider);

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
                    session.isLoggedIn ? 'Sesión activa' : 'Sin sesión',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (session.isLoggedIn) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(session.displayName),
                      subtitle: Text('${session.email}\nProveedor: ${session.provider}'),
                      isThreeLine: true,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(accountProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ] else ...[
                    const Text(
                      'Vincula una cuenta demo. El token se guarda en '
                      'almacenamiento seguro (flutter_secure_storage).',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(accountProvider.notifier).loginDemo(),
                      icon: const Icon(Icons.link),
                      label: const Text('Iniciar sesión demo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _customLogin(context, ref),
                      icon: const Icon(Icons.edit),
                      label: const Text('Login demo personalizado'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            'borradores locales / canales genéricos configurables.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _customLogin(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(text: 'Gerardo Vendedor');
    final email = TextEditingController(text: 'vendedor@mochila.market');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(accountProvider.notifier).loginDemo(
            name: name.text.trim(),
            email: email.text.trim(),
          );
    }
  }
}
