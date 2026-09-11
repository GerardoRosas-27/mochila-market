import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing_draft.dart';
import '../../../core/models/photo_group.dart';
import '../../../core/settings/public_base_url.dart';
import '../../../core/widgets/local_image.dart';
import '../../company/presentation/company_provider.dart';
import '../../inventory/presentation/inventory_provider.dart';
import '../../photo_groups/presentation/photo_group_provider.dart';
import '../../template/presentation/template_provider.dart';
import 'marketplace_provider.dart';

/// Admin: publicaciones = grupos de ofertas (productos del inventario).
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubs = ref.watch(marketplaceProvider);
    final groups = ref.watch(photoGroupProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicaciones'),
        actions: [
          IconButton(
            tooltip: 'Ver tienda pública',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.push('/tienda'),
          ),
          IconButton(
            tooltip: 'Grupos de fotos',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _managePhotoGroups(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPublication(context, ref),
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
                'Una publicación agrupa una o más mochilas del inventario '
                '(oferta). Tiene URL pública para responder en Marketplace. '
                '«Exportar como borrador» copia la plantilla al portapapeles; '
                'no publica a Facebook.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: pubs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay publicaciones. Crea una agrupando productos '
                        'del inventario.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: pubs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = pubs[index];
                      final imgs = _imagesForDraft(d, groups);
                      final nProd = d.allProductIds.length;
                      return Card(
                        child: ListTile(
                          leading: imgs.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LocalImage(
                                    path: imgs.first,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.local_offer),
                                ),
                          title: Text(d.title),
                          subtitle: Text(
                            'Desde ${currency.format(d.price)} · '
                            '$nProd producto(s) · ${d.status.labelEs}\n'
                            '/p/${d.slug}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              switch (v) {
                                case 'ver':
                                  context.push('/p/${d.slug}');
                                case 'editar':
                                  await _editPublication(context, ref, d);
                                case 'exportar':
                                  await _exportDraft(context, ref, d);
                                case 'copiar_url':
                                  await _copyShareUrl(context, ref, d);
                                case 'archivar':
                                  await ref
                                      .read(marketplaceProvider.notifier)
                                      .updateStatus(
                                        d.id,
                                        ListingStatus.archivada,
                                      );
                                case 'activar':
                                  await ref
                                      .read(marketplaceProvider.notifier)
                                      .updateStatus(
                                        d.id,
                                        ListingStatus.activa,
                                      );
                                case 'borrar':
                                  await ref
                                      .read(marketplaceProvider.notifier)
                                      .remove(d.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'ver',
                                child: Text('Ver oferta pública'),
                              ),
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'exportar',
                                child: Text('Exportar como borrador'),
                              ),
                              PopupMenuItem(
                                value: 'copiar_url',
                                child: Text('Copiar URL pública'),
                              ),
                              PopupMenuItem(
                                value: 'activar',
                                child: Text('Marcar activa'),
                              ),
                              PopupMenuItem(
                                value: 'archivar',
                                child: Text('Archivar'),
                              ),
                              PopupMenuItem(
                                value: 'borrar',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/p/${d.slug}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _imagesForDraft(ListingDraft d, List<PhotoGroup> groups) {
    final fromDraft = d.allImages;
    if (d.photoGroupId != null) {
      try {
        final g = groups.firstWhere((x) => x.id == d.photoGroupId);
        final merged = [...g.photoPaths, ...fromDraft];
        final seen = <String>{};
        return [for (final p in merged) if (seen.add(p)) p];
      } catch (_) {}
    }
    return fromDraft;
  }

  Future<void> _copyShareUrl(
    BuildContext context,
    WidgetRef ref,
    ListingDraft d,
  ) async {
    final url =
        ref.read(publicBaseUrlProvider.notifier).shareUrlForSlug(d.slug);
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL copiada: $url')),
    );
  }

  Future<void> _exportDraft(
    BuildContext context,
    WidgetRef ref,
    ListingDraft d,
  ) async {
    final text = ref.read(marketplaceProvider.notifier).exportMarketplaceText(
          publication: d,
          products: ref.read(inventoryProvider),
          template: ref.read(templateProvider),
          company: ref.read(companyProvider),
        );
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Borrador Marketplace copiado. Pégalo en Facebook Marketplace.',
        ),
      ),
    );
  }

  Future<void> _createPublication(BuildContext context, WidgetRef ref) async {
    final products = ref.read(inventoryProvider);
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero agrega productos al inventario.')),
      );
      return;
    }

    final selected = <String>{};
    final titleCtrl = TextEditingController();
    String? photoGroupId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nueva publicación (grupo de ofertas)'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título de la oferta',
                      hintText: 'Ej. Pack mochilas urbanas',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona productos del inventario',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...products.map(
                    (p) => CheckboxListTile(
                      dense: true,
                      value: selected.contains(p.id),
                      title: Text(p.name),
                      subtitle: Text(
                        '\$${p.price.toStringAsFixed(0)} · stock ${p.stock}',
                      ),
                      onChanged: (v) => setLocal(() {
                        if (v == true) {
                          selected.add(p.id);
                        } else {
                          selected.remove(p.id);
                        }
                      }),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final id = await _pickPhotoGroupOptional(context, ref);
                      setLocal(() => photoGroupId = id);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      photoGroupId == null
                          ? 'Grupo de fotos (opcional)'
                          : 'Grupo de fotos ✓',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    final chosen = products.where((p) => selected.contains(p.id)).toList();
    final draft =
        await ref.read(marketplaceProvider.notifier).createOfferGroup(
              title: titleCtrl.text,
              products: chosen,
              photoGroupId: photoGroupId,
              template: ref.read(templateProvider),
              company: ref.read(companyProvider),
            );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Publicación creada · /p/${draft.slug}'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => context.push('/p/${draft.slug}'),
        ),
      ),
    );
  }

  Future<void> _editPublication(
    BuildContext context,
    WidgetRef ref,
    ListingDraft existing,
  ) async {
    final products = ref.read(inventoryProvider);
    final titleCtrl = TextEditingController(text: existing.title);
    final descCtrl = TextEditingController(text: existing.description);
    final selected = existing.allProductIds.toSet();
    String? photoGroupId = existing.photoGroupId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar publicación'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 8),
                  ...products.map(
                    (p) => CheckboxListTile(
                      dense: true,
                      value: selected.contains(p.id),
                      title: Text(p.name),
                      onChanged: (v) => setLocal(() {
                        if (v == true) {
                          selected.add(p.id);
                        } else {
                          selected.remove(p.id);
                        }
                      }),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final id = await _pickPhotoGroupOptional(context, ref);
                      setLocal(() => photoGroupId = id);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      photoGroupId == null ? 'Grupo fotos' : 'Grupo fotos ✓',
                    ),
                  ),
                ],
              ),
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
    final ids = selected.toList();
    final chosen = products.where((p) => ids.contains(p.id)).toList();
    final prices = chosen.map((p) => p.price).toList()..sort();
    await ref.read(marketplaceProvider.notifier).updateDraft(
          existing.copyWith(
            title: titleCtrl.text.trim().isEmpty
                ? existing.title
                : titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
            productIds: ids,
            productId: ids.isNotEmpty ? ids.first : existing.productId,
            price: prices.isNotEmpty ? prices.first : existing.price,
            photoGroupId: photoGroupId,
            clearPhotoGroupId: photoGroupId == null,
          ),
        );
  }

  Future<String?> _pickPhotoGroupOptional(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final groups = ref.read(photoGroupProvider);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Grupo de fotos (opcional)'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Sin grupo'),
          ),
          ...groups.map(
            (g) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g.id),
              child: Text('${g.name} (${g.photoPaths.length} fotos)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, '__new__'),
            child: const Text('Crear grupo nuevo…'),
          ),
        ],
      ),
    );
    if (choice == null || choice.isEmpty) return null;
    if (choice == '__new__') {
      if (!context.mounted) return null;
      return _createPhotoGroupFlow(context, ref);
    }
    return choice;
  }

  Future<String?> _createPhotoGroupFlow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameCtrl = TextEditingController(text: 'Grupo ${DateTime.now().day}');
    var photos = <String>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo grupo de fotos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              Text('${photos.length} foto(s) seleccionadas'),
              TextButton.icon(
                onPressed: () async {
                  final files = await ImagePicker().pickMultiImage();
                  if (files.isEmpty) return;
                  setLocal(() {
                    photos = [...photos, ...files.map((f) => f.path)];
                  });
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Agregar fotos'),
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
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    final g = await ref.read(photoGroupProvider.notifier).create(
          name: nameCtrl.text,
          photoPaths: photos,
        );
    return g.id;
  }

  Future<void> _managePhotoGroups(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final groups = ref.watch(photoGroupProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Grupos de fotos',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            await _createPhotoGroupFlow(context, ref);
                          },
                        ),
                      ],
                    ),
                    if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aún no hay grupos.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: groups.length,
                          itemBuilder: (_, i) {
                            final g = groups[i];
                            return ListTile(
                              leading: g.photoPaths.isNotEmpty
                                  ? LocalImage(
                                      path: g.photoPaths.first,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.photo),
                              title: Text(g.name),
                              subtitle: Text('${g.photoPaths.length} foto(s)'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref
                                    .read(photoGroupProvider.notifier)
                                    .remove(g.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
