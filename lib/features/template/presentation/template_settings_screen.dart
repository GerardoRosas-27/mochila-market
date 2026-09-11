import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/marketplace_template.dart';
import 'template_provider.dart';

class TemplateSettingsScreen extends ConsumerStatefulWidget {
  const TemplateSettingsScreen({super.key});

  @override
  ConsumerState<TemplateSettingsScreen> createState() =>
      _TemplateSettingsScreenState();
}

class _TemplateSettingsScreenState
    extends ConsumerState<TemplateSettingsScreen> {
  late TextEditingController _title;
  late TextEditingController _body;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _body = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    final t = ref.read(templateProvider);
    _title.text = t.titleTemplate;
    _body.text = t.bodyTemplate;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(templateProvider.notifier).save(
          MarketplaceTemplate(
            titleTemplate: _title.text,
            bodyTemplate: _body.text,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla guardada')),
      );
    }
  }

  Future<void> _reset() async {
    _title.text = MarketplaceTemplate.defaultTitle;
    _body.text = MarketplaceTemplate.defaultBody;
    setState(() {});
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(templateProvider, (_, __) {
      if (!_ready) _sync();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantilla Marketplace'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Los borradores rellenan estos textos con datos del producto '
            'y de la empresa. No se publica a Facebook desde la app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Plantilla de título',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Plantilla de cuerpo',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Placeholders disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MarketplaceTemplate.supportedPlaceholders
                .map(
                  (p) => ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      final text = _body.text;
                      final sel = _body.selection;
                      final start =
                          sel.isValid ? sel.start : text.length;
                      final end = sel.isValid ? sel.end : text.length;
                      final next = text.replaceRange(start, end, p);
                      _body.text = next;
                      _body.selection = TextSelection.collapsed(
                        offset: start + p.length,
                      );
                      setState(() {});
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar plantilla'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar valores por defecto'),
          ),
        ],
      ),
    );
  }
}
