import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/meta_config.dart';
import 'meta_provider.dart';

class MetaSettingsScreen extends ConsumerStatefulWidget {
  const MetaSettingsScreen({super.key});

  @override
  ConsumerState<MetaSettingsScreen> createState() => _MetaSettingsScreenState();
}

class _MetaSettingsScreenState extends ConsumerState<MetaSettingsScreen> {
  late TextEditingController _appId;
  late TextEditingController _appSecret;
  late TextEditingController _token;
  late TextEditingController _pageId;
  late TextEditingController _version;
  var _ready = false;
  var _busy = false;
  String? _status;
  List<MetaPageInfo> _pages = [];

  @override
  void initState() {
    super.initState();
    _appId = TextEditingController();
    _appSecret = TextEditingController();
    _token = TextEditingController();
    _pageId = TextEditingController();
    _version = TextEditingController(text: 'v21.0');
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final s = ref.read(metaProvider);
    _appId.text = s.appId;
    _appSecret.text = s.appSecret;
    _token.text = s.userAccessToken;
    _pageId.text = s.pageId;
    _version.text = s.graphApiVersion;
    _status = s.lastValidationMessage.isEmpty ? null : s.lastValidationMessage;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _appId.dispose();
    _appSecret.dispose();
    _token.dispose();
    _pageId.dispose();
    _version.dispose();
    super.dispose();
  }

  MetaConfig _fromFields() => MetaConfig(
        appId: _appId.text.trim(),
        appSecret: _appSecret.text.trim(),
        userAccessToken: _token.text.trim(),
        pageId: _pageId.text.trim(),
        graphApiVersion:
            _version.text.trim().isEmpty ? 'v21.0' : _version.text.trim(),
        lastValidationMessage: ref.read(metaProvider).lastValidationMessage,
        lastValidatedAt: ref.read(metaProvider).lastValidatedAt,
        connectionOk: ref.read(metaProvider).connectionOk,
      );

  Future<void> _save() async {
    await ref.read(metaProvider.notifier).save(_fromFields());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración Meta guardada')),
      );
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await _save();
      await action();
      setState(() {
        _status = ref.read(metaProvider.notifier).lastActionMessage;
        _pages = List.of(ref.read(metaProvider.notifier).pages);
      });
    } catch (e) {
      setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(metaProvider, (_, __) {
      if (!_ready) _sync();
    });
    final cfg = ref.watch(metaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meta Graph API'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Configura tu app en developers.facebook.com. '
                'Los secretos (App Secret y token) van a flutter_secure_storage; '
                'App ID / Page ID / versión a SharedPreferences.\n\n'
                '✅ Funciona sin revisión especial (con token de usuario/página): '
                'validar /me, listar páginas (me/accounts), publicar en feed '
                'de Página (/{page-id}/feed) si tienes pages_manage_posts.\n'
                '⚠️ Requiere App Review / permisos avanzados: mensajería, '
                'insights, muchos scopes de negocio.\n'
                '🚫 No disponible vía Graph API pública: crear ítems de '
                'Facebook Marketplace. Usa «Publicación en Página / borrador» '
                'en su lugar. No se hace scraping.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appId,
            decoration: const InputDecoration(
              labelText: 'App ID',
              helperText: 'Identificador de la app Meta',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _appSecret,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'App Secret',
              helperText: 'Almacenamiento seguro',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _token,
            obscureText: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'User access token / long-lived',
              helperText: 'Token de usuario o de página (secure storage)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pageId,
            decoration: const InputDecoration(
              labelText: 'Page ID',
              helperText: 'Página donde publicar en el feed',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _version,
            decoration: const InputDecoration(
              labelText: 'Versión Graph API (opcional)',
              helperText: 'Ej. v21.0',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () async {
                            await ref
                                .read(metaProvider.notifier)
                                .validateToken();
                          },
                        ),
                icon: const Icon(Icons.verified_user),
                label: const Text('Validar token'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () async {
                            await ref.read(metaProvider.notifier).listPages();
                          },
                        ),
                icon: const Icon(Icons.pages),
                label: const Text('Listar páginas'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          () async {
                            final r = await ref
                                .read(metaProvider.notifier)
                                .publishPagePost(
                                  'Prueba MochilaMarket · '
                                  '${DateTime.now().toIso8601String()}',
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  r.ok
                                      ? 'OK: ${r.postId ?? r.message}'
                                      : r.message,
                                ),
                              ),
                            );
                          },
                        ),
                icon: const Icon(Icons.publish),
                label: const Text('Probar post Página'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              cfg.connectionOk ? Icons.check_circle : Icons.cloud_off,
              color: cfg.connectionOk ? Colors.green : Colors.grey,
            ),
            title: Text(
              cfg.connectionOk
                  ? 'Conexión: OK'
                  : 'Conexión: sin validar / error',
            ),
            subtitle: Text(
              _status ??
                  (cfg.lastValidationMessage.isEmpty
                      ? 'Aún no se ha validado el token'
                      : cfg.lastValidationMessage),
            ),
          ),
          if (_pages.isNotEmpty) ...[
            const Divider(),
            Text(
              'Páginas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._pages.map(
              (p) => ListTile(
                title: Text(p.name),
                subtitle: Text('${p.id}${p.category != null ? ' · ${p.category}' : ''}'),
                trailing: TextButton(
                  child: const Text('Usar'),
                  onPressed: () {
                    _pageId.text = p.id;
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar configuración'),
          ),
        ],
      ),
    );
  }
}
