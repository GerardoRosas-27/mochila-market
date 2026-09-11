import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ai_settings.dart';
import 'ai_settings_provider.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late TextEditingController _imageBase;
  late TextEditingController _imageKey;
  late TextEditingController _imageModel;
  late TextEditingController _multiBase;
  late TextEditingController _multiKey;
  late TextEditingController _multiModel;
  late TextEditingController _removeKey;
  late TextEditingController _genericEndpoint;
  BgProvider _bg = BgProvider.demo;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _imageBase = TextEditingController();
    _imageKey = TextEditingController();
    _imageModel = TextEditingController();
    _multiBase = TextEditingController();
    _multiKey = TextEditingController();
    _multiModel = TextEditingController();
    _removeKey = TextEditingController();
    _genericEndpoint = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());
  }

  void _syncFromState() {
    final s = ref.read(aiSettingsProvider);
    _imageBase.text = s.imageApiBaseUrl;
    _imageKey.text = s.imageApiKey;
    _imageModel.text = s.imageModel;
    _multiBase.text = s.multimodalApiBaseUrl;
    _multiKey.text = s.multimodalApiKey;
    _multiModel.text = s.multimodalModel;
    _removeKey.text = s.removeBgApiKey;
    _genericEndpoint.text = s.genericBgEndpoint;
    _bg = s.bgProvider;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _imageBase.dispose();
    _imageKey.dispose();
    _imageModel.dispose();
    _multiBase.dispose();
    _multiKey.dispose();
    _multiModel.dispose();
    _removeKey.dispose();
    _genericEndpoint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = AiSettings(
      imageApiBaseUrl: _imageBase.text.trim(),
      imageApiKey: _imageKey.text.trim(),
      imageModel: _imageModel.text.trim().isEmpty
          ? 'gpt-image-1'
          : _imageModel.text.trim(),
      multimodalApiBaseUrl: _multiBase.text.trim(),
      multimodalApiKey: _multiKey.text.trim(),
      multimodalModel: _multiModel.text.trim().isEmpty
          ? 'gpt-4o-mini'
          : _multiModel.text.trim(),
      removeBgApiKey: _removeKey.text.trim(),
      genericBgEndpoint: _genericEndpoint.text.trim(),
      bgProvider: _bg,
    );
    await ref.read(aiSettingsProvider.notifier).save(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustes guardados de forma segura')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(aiSettingsProvider, (_, __) {
      if (!_ready) _syncFromState();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes IA'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Proveedor de fondo (pluggable)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<BgProvider>(
            segments: const [
              ButtonSegment(
                value: BgProvider.demo,
                label: Text('Demo'),
                icon: Icon(Icons.science),
              ),
              ButtonSegment(
                value: BgProvider.removeBg,
                label: Text('remove.bg'),
                icon: Icon(Icons.cloud),
              ),
              ButtonSegment(
                value: BgProvider.genericHttp,
                label: Text('HTTP'),
                icon: Icon(Icons.api),
              ),
            ],
            selected: {_bg},
            onSelectionChanged: (s) => setState(() => _bg = s.first),
          ),
          const SizedBox(height: 8),
          if (_bg == BgProvider.removeBg)
            TextField(
              controller: _removeKey,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API key remove.bg',
                helperText: 'Se guarda en secure storage',
              ),
            ),
          if (_bg == BgProvider.genericHttp)
            TextField(
              controller: _genericEndpoint,
              decoration: const InputDecoration(
                labelText: 'Endpoint HTTP genérico',
                helperText:
                    'URL completa, o vacío para {base URL imagen}/remove-bg',
              ),
            ),
          const Divider(height: 32),
          Text(
            'API de imagen (externa)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _imageBase,
            decoration: const InputDecoration(
              labelText: 'Base URL (p. ej. https://api.openai.com/v1)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _imageModel,
            decoration: const InputDecoration(labelText: 'Modelo / model id'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _imageKey,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API key imagen',
              helperText: 'Secure storage',
            ),
          ),
          const Divider(height: 32),
          Text(
            'API multimodal (inbox / captions)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _multiBase,
            decoration: const InputDecoration(
              labelText: 'Base URL chat/completions',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _multiModel,
            decoration: const InputDecoration(labelText: 'Modelo multimodal'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _multiKey,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API key multimodal',
              helperText: 'Secure storage',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar ajustes'),
          ),
        ],
      ),
    );
  }
}
