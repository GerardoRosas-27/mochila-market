import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing_draft.dart';
import '../../../core/models/photo_group.dart';
import '../../../core/models/product.dart';
import '../../../core/widgets/local_image.dart';
import '../../company/presentation/company_provider.dart';
import '../../inventory/presentation/inventory_provider.dart';
import '../../photo_groups/presentation/photo_group_provider.dart';
import '../../template/presentation/template_provider.dart';
import 'marketplace_provider.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(marketplaceProvider);
    final groups = ref.watch(photoGroupProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borradores Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Grupos de fotos',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => _managePhotoGroups(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFlow(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo borrador'),
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Solo borradores locales. Usa la plantilla configurable '
                '(Cuenta → Plantilla) y copia el texto para pegarlo en '
                'Marketplace. La app no publica a Facebook.',
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
                        'No hay borradores. Elige un producto del inventario '
                        'o crea uno manual con fotos / grupo de fotos.',
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
                      final imgs = _imagesForDraft(d, groups);
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
                                  child: Icon(Icons.backpack),
                                ),
                          title: Text(d.title),
                          subtitle: Text(
                            '${currency.format(d.price)} · '
                            '${d.status.labelEs}'
                            '${d.photoGroupId != null ? ' · grupo fotos' : ''}'
                            '${imgs.length > 1 ? ' · ${imgs.length} fotos' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              final n =
                                  ref.read(marketplaceProvider.notifier);
                              switch (v) {
                                case 'editar':
                                  await _editDraft(context, ref, d);
                                case 'copiar':
                                  await _copyDraft(context, d);
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
                                value: 'copiar',
                                child: Text('Copiar texto (pegar fuera)'),
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

  List<String> _imagesForDraft(
    ListingDraft d,
    List<PhotoGroup> groups,
  ) {
    final fromDraft = d.allImages;
    if (d.photoGroupId != null) {
      try {
        final g = groups.firstWhere((x) => x.id == d.photoGroupId);
        final merged = [...g.photoPaths, ...fromDraft];
        final seen = <String>{};
        return [
          for (final p in merged)
            if (seen.add(p)) p,
        ];
      } catch (_) {}
    }
    return fromDraft;
  }

  Future<void> _copyDraft(BuildContext context, ListingDraft d) async {
    final text = '${d.title}\n\n${d.description}\n\nPrecio: '
        '\$${d.price.toStringAsFixed(0)} MXN';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado. Pégalo en Marketplace u otra app.'),
      ),
    );
  }

  Future<void> _showCreateFlow(BuildContext context, WidgetRef ref) async {
    final products = ref.read(inventoryProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Nuevo borrador'),
              subtitle: Text('Plantilla + inventario o manual'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Desde inventario (aplica plantilla)'),
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
      final product = await _pickProduct(context, products);
      if (product == null || !context.mounted) return;
      final groupId = await _pickPhotoGroupOptional(context, ref);
      if (!context.mounted) return;
      final template = ref.read(templateProvider);
      final company = ref.read(companyProvider);
      final draft = await ref.read(marketplaceProvider.notifier).createFromProduct(
            product: product,
            template: template,
            company: company,
            photoGroupId: groupId,
          );
      if (!context.mounted) return;
      await _editDraft(context, ref, draft);
    } else {
      await _editDraft(context, ref, null);
    }
  }

  Future<Product?> _pickProduct(
    BuildContext context,
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
                              subtitle:
                                  Text('${g.photoPaths.length} foto(s)'),
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
    var photos = List<String>.from(existing?.imagePaths ?? const []);
    if (photos.isEmpty && existing?.imagePath != null) {
      photos = [existing!.imagePath!];
    }
    String? photoGroupId = existing?.photoGroupId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isNew ? 'Nuevo borrador' : 'Editar borrador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < photos.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                LocalImage(
                                  path: photos[i],
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () => setLocal(
                                      () => photos = [...photos]..removeAt(i),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final files = await ImagePicker().pickMultiImage();
                        if (files.isEmpty) return;
                        setLocal(() {
                          photos = [
                            ...photos,
                            ...files.map((f) => f.path),
                          ];
                        });
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Fotos'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final id =
                            await _pickPhotoGroupOptional(context, ref);
                        setLocal(() => photoGroupId = id);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        photoGroupId == null ? 'Grupo' : 'Grupo ✓',
                      ),
                    ),
                  ],
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
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Descripción'),
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
      await n.create(
        title: titleCtrl.text.trim().isEmpty
            ? 'Sin título'
            : titleCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0,
        description: descCtrl.text.trim(),
        imagePaths: photos,
        photoGroupId: photoGroupId,
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
          imagePaths: photos,
          imagePath: photos.isNotEmpty ? photos.first : existing.imagePath,
          photoGroupId: photoGroupId,
          clearPhotoGroupId: photoGroupId == null,
        ),
      );
    }
  }
}
