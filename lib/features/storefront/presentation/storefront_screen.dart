import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/product.dart';
import '../../../core/widgets/local_image.dart';
import '../../inventory/presentation/inventory_provider.dart';

/// Tienda pública: lista TODAS las mochilas disponibles del inventario.
class StorefrontScreen extends ConsumerWidget {
  const StorefrontScreen({super.key, this.showAdminLink = true});

  final bool showAdminLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryProvider);
    final available = items
        .where((p) => p.available && p.stock > 0)
        .toList();
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de mochilas'),
        actions: [
          if (showAdminLink)
            TextButton(
              onPressed: () => context.go('/publicaciones'),
              child: const Text('Admin'),
            ),
        ],
      ),
      body: available.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay mochilas disponibles por ahora.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                final cross = wide
                    ? (constraints.maxWidth / 220).floor().clamp(2, 4)
                    : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final p = available[index];
                    return _ProductCard(
                      product: p,
                      priceLabel: currency.format(p.price),
                      onTap: () => context.push('/producto/${p.id}'),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceLabel,
    required this.onTap,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.primaryPhoto != null
                  ? LocalImage(
                      path: product.primaryPhoto!,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.backpack, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
