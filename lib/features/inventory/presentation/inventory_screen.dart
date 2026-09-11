import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/local_image.dart';
import 'inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Sin productos. Agrega el primero.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final b = items[index];
                return Card(
                  child: ListTile(
                    leading: b.primaryPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LocalImage(
                              path: b.primaryPhoto!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : CircleAvatar(
                            child: Text(
                              b.brand.isNotEmpty
                                  ? b.brand[0]
                                  : (b.name.isNotEmpty ? b.name[0] : '?'),
                            ),
                          ),
                    title: Text(b.name),
                    subtitle: Text(
                      '${b.brand.isEmpty ? 'Sin marca' : b.brand}'
                      ' · SKU ${b.sku.isEmpty ? '—' : b.sku}'
                      ' · stock ${b.stock}'
                      '${b.available ? '' : ' · agotado'}\n'
                      '${currency.format(b.price)} · ${b.condition.labelEs}'
                      '${b.colors.isEmpty ? '' : ' · ${b.colors.join(", ")}'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'editar') {
                          _editDialog(context, ref, b);
                        } else if (v == 'borrar') {
                          ref.read(inventoryProvider.notifier).remove(b.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'borrar', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () => _editDialog(context, ref, b),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editDialog(
    BuildContext context,
    WidgetRef ref,
    Product? existing,
  ) async {
    final isNew = existing == null;
    final name = TextEditingController(text: existing?.name ?? '');
    final brand = TextEditingController(text: existing?.brand ?? '');
    final price = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final desc = TextEditingController(text: existing?.description ?? '');
    final sku = TextEditingController(text: existing?.sku ?? '');
    final stock = TextEditingController(
      text: existing != null ? '${existing.stock}' : '1',
    );
    final colors = TextEditingController(
      text: existing?.colors.join(', ') ?? '',
    );
    final sizes = TextEditingController(
      text: existing?.sizes.join(', ') ?? '',
    );
    final material = TextEditingController(text: existing?.material ?? '');
    final tags = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    final location = TextEditingController(
      text: existing?.locationOverride ?? '',
    );
    final category =
        TextEditingController(text: existing?.category ?? 'mochila');
    var available = existing?.available ?? true;
    var condition = existing?.condition ?? ProductCondition.nuevo;
    var photos = List<String>.from(existing?.photoPaths ?? const []);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isNew ? 'Nuevo producto' : 'Editar producto'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photos.isNotEmpty)
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            LocalImage(
                              path: photos[i],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => setLocal(
                                  () => photos = [...photos]..removeAt(i),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final files = await picker.pickMultiImage();
                      if (files.isEmpty) return;
                      setLocal(() {
                        photos = [
                          ...photos,
                          ...files.map((f) => f.path),
                        ];
                      });
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar fotos'),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: brand,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible'),
                    value: available,
                    onChanged: (v) => setLocal(() => available = v),
                  ),
                  DropdownButtonFormField<ProductCondition>(
                    initialValue: condition,
                    decoration: const InputDecoration(labelText: 'Condición'),
                    items: ProductCondition.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.labelEs),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => condition = v ?? condition),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: colors,
                    decoration: const InputDecoration(
                      labelText: 'Colores (separados por coma)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sizes,
                    decoration: const InputDecoration(
                      labelText: 'Tamaños (separados por coma)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: material,
                    decoration: const InputDecoration(labelText: 'Material'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tags,
                    decoration: const InputDecoration(
                      labelText: 'Etiquetas (coma)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación (opcional, override)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: desc,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Descripción'),
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

    List<String> split(String s) => s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final notifier = ref.read(inventoryProvider.notifier);
    final item = (existing ?? notifier.createDraft()).copyWith(
      name: name.text.trim().isEmpty ? 'Sin nombre' : name.text.trim(),
      brand: brand.text.trim(),
      price: double.tryParse(price.text.replaceAll(',', '')) ?? 0,
      description: desc.text.trim(),
      sku: sku.text.trim(),
      stock: int.tryParse(stock.text) ?? 1,
      available: available,
      colors: split(colors.text),
      sizes: split(sizes.text),
      material: material.text.trim(),
      condition: condition,
      tags: split(tags.text),
      photoPaths: photos,
      locationOverride: location.text.trim(),
      category:
          category.text.trim().isEmpty ? 'mochila' : category.text.trim(),
    );
    if (isNew) {
      await notifier.add(item);
    } else {
      await notifier.update(item);
    }
  }
}
