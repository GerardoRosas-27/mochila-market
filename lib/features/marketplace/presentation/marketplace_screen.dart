import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing_draft.dart';
import '../../../core/models/product.dart';
import '../../../core/widgets/local_image.dart';
import '../../inventory/presentation/inventory_provider.dart';
import '../../meta/presentation/meta_provider.dart';
import 'marketplace_provider.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(marketplaceProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones / Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFlow(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva publicación'),
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Facebook Marketplace (ítems) no está disponible vía Graph API '
                'pública. Puedes crear borradores locales o publicar en el '
                'feed de tu Página Meta. Sin scraping.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: drafts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay publicaciones. Elige un producto del inventario '
                        'o crea un borrador manual.',
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
                      final img = d.allImages;
                      return Card(
                        child: ListTile(
                          leading: img.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LocalImage(
                                    path: img.first,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.backpack),
                                ),
                          title: Text(d.title),
                          subtitle: Text(
                            '${currency.format(d.price)} · '
                            '${d.publishChannel.labelEs}\n'
                            '${_statusLabel(d.status)}'
                            '${d.metaPostId != null ? ' · ${d.metaPostId}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              final n =
                                  ref.read(marketplaceProvider.notifier);
                              switch (v) {
                                case 'editar':
                                  await _editDraft(context, ref, d);
                                case 'page':
                                  await _publishToPage(context, ref, d);
                                case 'listo':
                                  await n.updateStatus(
                                    d.id,
                                    ListingStatus.listo,
                                  );
                                case 'publicado':
                                  await n.updateStatus(
                                    d.id,
                                    ListingStatus.publicado,
                                  );
                                case 'borrar':
                                  await n.remove(d.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'page',
                                child: Text('Publicar en Página (Graph)'),
                              ),
                              PopupMenuItem(
                                value: 'listo',
                                child: Text('Marcar listo'),
                              ),
                              PopupMenuItem(
                                value: 'publicado',
                                child: Text('Marcar publicado (local)'),
                              ),
                              PopupMenuItem(
                                value: 'borrar',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                          onTap: () => _editDraft(context, ref, d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ListingStatus s) => switch (s) {
        ListingStatus.borrador => 'Borrador',
        ListingStatus.listo => 'Listo',
        ListingStatus.publicado => 'Publicado',
      };

  Future<void> _showCreateFlow(BuildContext context, WidgetRef ref) async {
    final products = ref.read(inventoryProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Nueva publicación'),
              subtitle: Text('Prefill desde inventario o manual'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Desde inventario'),
              enabled: products.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 'inventory'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Borrador manual'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'inventory') {
      final product = await _pickProduct(context, ref, products);
      if (product == null || !context.mounted) return;
      final draft =
          ref.read(marketplaceProvider.notifier).createFromProduct(product);
      await _editDraft(context, ref, draft);
    } else {
      await _editDraft(context, ref, null);
    }
  }

  Future<Product?> _pickProduct(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) {
    return showDialog<Product>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Elegir producto'),
        children: products
            .map(
              (p) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, p),
                child: Text('${p.name} · \$${p.price.toStringAsFixed(0)}'),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _editDraft(
    BuildContext context,
    WidgetRef ref,
    ListingDraft? existing,
  ) async {
    final isNew = existing == null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    var channel = existing?.publishChannel ?? PublishChannel.borradorLocal;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isNew ? 'Nuevo borrador' : 'Editar publicación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing != null && existing.allImages.isNotEmpty)
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: existing.allImages
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: LocalImage(
                                path: p,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
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
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PublishChannel>(
                  initialValue: channel,
                  decoration: const InputDecoration(labelText: 'Canal'),
                  items: PublishChannel.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.labelEs),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => channel = v ?? channel),
                ),
                if (channel == PublishChannel.marketplaceNoDisponible)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Marketplace de ítems requiere herramientas de Meta '
                      'fuera de la API pública. Guarda como borrador o '
                      'publica en el feed de Página.',
                      style: TextStyle(fontSize: 12),
                    ),
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

    if (ok != true || !context.mounted) return;
    final n = ref.read(marketplaceProvider.notifier);
    if (isNew) {
      n.create(
        title: titleCtrl.text.trim().isEmpty
            ? 'Sin título'
            : titleCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0,
        description: descCtrl.text.trim(),
        publishChannel: channel,
        marketplace: channel == PublishChannel.pageFeed ? 'page_feed' : 'demo',
      );
    } else {
      await n.updateDraft(
        existing.copyWith(
          title: titleCtrl.text.trim().isEmpty
              ? existing.title
              : titleCtrl.text.trim(),
          price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ??
              existing.price,
          description: descCtrl.text.trim(),
          publishChannel: channel,
        ),
      );
    }
  }

  Future<void> _publishToPage(
    BuildContext context,
    WidgetRef ref,
    ListingDraft d,
  ) async {
    final meta = ref.read(metaProvider);
    if (!meta.hasToken || meta.pageId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configura Meta Graph (token + Page ID) en Cuenta → Meta Graph API',
          ),
        ),
      );
      return;
    }
    final message =
        '${d.title}\n\n${d.description}\n\nPrecio: \$${d.price.toStringAsFixed(0)} MXN';
    final result =
        await ref.read(metaProvider.notifier).publishPagePost(message);
    if (!context.mounted) return;
    if (result.ok) {
      await ref.read(marketplaceProvider.notifier).updateDraft(
            d.copyWith(
              status: ListingStatus.publicado,
              metaPostId: result.postId,
              publishChannel: PublishChannel.pageFeed,
            ),
          );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }
}
