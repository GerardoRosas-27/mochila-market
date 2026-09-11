import 'package:flutter/material.dart';
import '../../../core/widgets/local_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing_draft.dart';
import 'marketplace_provider.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(marketplaceProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Borradores Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo borrador'),
      ),
      body: drafts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay borradores. Captura una foto o crea uno manual.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: drafts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = drafts[index];
                return Card(
                  child: ListTile(
                    leading: d.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LocalImage(
                              path: d.imagePath!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.backpack)),
                    title: Text(d.title),
                    subtitle: Text(
                      '${currency.format(d.price)} · ${d.marketplace} · '
                      '${_statusLabel(d.status)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        final n = ref.read(marketplaceProvider.notifier);
                        switch (v) {
                          case 'listo':
                            n.updateStatus(d.id, ListingStatus.listo);
                          case 'publicado':
                            n.updateStatus(d.id, ListingStatus.publicado);
                          case 'borrar':
                            n.remove(d.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'listo',
                          child: Text('Marcar listo'),
                        ),
                        PopupMenuItem(
                          value: 'publicado',
                          child: Text('Marcar publicado'),
                        ),
                        PopupMenuItem(
                          value: 'borrar',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _statusLabel(ListingStatus s) => switch (s) {
        ListingStatus.borrador => 'Borrador',
        ListingStatus.listo => 'Listo',
        ListingStatus.publicado => 'Publicado',
      };

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String marketplace = 'demo';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo borrador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (MXN)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: marketplace,
                  decoration: const InputDecoration(labelText: 'Canal'),
                  items: const [
                    DropdownMenuItem(value: 'demo', child: Text('Demo local')),
                    DropdownMenuItem(
                      value: 'marketplace',
                      child: Text('Marketplace genérico'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => marketplace = v ?? 'demo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      ref.read(marketplaceProvider.notifier).create(
            title: titleCtrl.text.trim().isEmpty
                ? 'Sin título'
                : titleCtrl.text.trim(),
            price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0,
            description: descCtrl.text.trim(),
            marketplace: marketplace,
          );
    }
  }
}
