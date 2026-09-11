import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/backpack.dart';
import 'catalog_provider.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(catalogProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de mochilas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final b = items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(b.brand.isNotEmpty ? b.brand[0] : '?'),
              ),
              title: Text(b.name),
              subtitle: Text(
                '${b.brand} · ${b.category} · stock ${b.stock}\n'
                '${currency.format(b.price)}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'editar') {
                    _editDialog(context, ref, b);
                  } else if (v == 'borrar') {
                    ref.read(catalogProvider.notifier).remove(b.id);
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
    Backpack? existing,
  ) async {
    final isNew = existing == null;
    final name = TextEditingController(text: existing?.name ?? '');
    final brand = TextEditingController(text: existing?.brand ?? '');
    final price = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final desc = TextEditingController(text: existing?.description ?? '');
    final category = TextEditingController(text: existing?.category ?? 'mochila');
    final stock = TextEditingController(
      text: existing != null ? '${existing.stock}' : '1',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Nueva mochila' : 'Editar mochila'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: desc,
                maxLines: 3,
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
    );

    if (ok != true || !context.mounted) return;

    final notifier = ref.read(catalogProvider.notifier);
    final item = (existing ?? notifier.createDraft()).copyWith(
      name: name.text.trim().isEmpty ? 'Sin nombre' : name.text.trim(),
      brand: brand.text.trim(),
      price: double.tryParse(price.text.replaceAll(',', '')) ?? 0,
      description: desc.text.trim(),
      category: category.text.trim().isEmpty ? 'mochila' : category.text.trim(),
      stock: int.tryParse(stock.text) ?? 1,
    );
    if (isNew) {
      notifier.add(item);
    } else {
      notifier.update(item);
    }
  }
}
