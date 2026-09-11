import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/product.dart';
import '../../../core/settings/public_base_url.dart';
import '../../../core/widgets/local_image.dart';
import '../../inventory/presentation/inventory_provider.dart';

/// Detalle público de un producto del inventario (precio + características).
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    Product? product;
    try {
      product = items.firstWhere((p) => p.id == productId);
    } catch (_) {
      product = null;
    }
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final base = ref.watch(publicBaseUrlProvider);
    final share = ref
        .read(publicBaseUrlProvider.notifier)
        .shareUrlForProduct(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Producto no encontrado'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/tienda'),
                child: const Text('Volver a la tienda'),
              ),
            ],
          ),
        ),
      );
    }

    final p = product;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            tooltip: 'Copiar enlace',
            icon: const Icon(Icons.link),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: share));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    base.isEmpty
                        ? 'Ruta copiada: $share (configura URL pública en Cuenta)'
                        : 'Enlace copiado: $share',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.photoPaths.isNotEmpty)
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.photoPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LocalImage(
                    path: p.photoPaths[i],
                    width: 240,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              height: 160,
              child: Center(child: Icon(Icons.backpack, size: 72)),
            ),
          const SizedBox(height: 16),
          Text(
            currency.format(p.price),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (p.brand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Marca: ${p.brand}'),
          ],
          const SizedBox(height: 12),
          if (p.description.isNotEmpty) Text(p.description),
          const SizedBox(height: 16),
          Text(
            'Características',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _kv('SKU', p.sku.isEmpty ? '—' : p.sku),
          _kv('Stock', '${p.stock}'),
          _kv('Condición', p.condition.labelEs),
          if (p.colors.isNotEmpty) _kv('Colores', p.colors.join(', ')),
          if (p.sizes.isNotEmpty) _kv('Tallas / capacidad', p.sizes.join(', ')),
          if (p.material.isNotEmpty) _kv('Material', p.material),
          if (p.tags.isNotEmpty) _kv('Etiquetas', p.tags.join(', ')),
          if (p.locationOverride.isNotEmpty)
            _kv('Ubicación', p.locationOverride),
          _kv('Categoría', p.category),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.go('/tienda'),
            icon: const Icon(Icons.storefront),
            label: const Text('Ver todas las mochilas'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
