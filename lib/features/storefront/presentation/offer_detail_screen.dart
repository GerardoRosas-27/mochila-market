import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/listing_draft.dart';
import '../../../core/models/product.dart';
import '../../../core/settings/public_base_url.dart';
import '../../../core/widgets/local_image.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../company/presentation/company_provider.dart';
import '../../inventory/presentation/inventory_provider.dart';
import '../../marketplace/presentation/marketplace_provider.dart';
import '../../photo_groups/presentation/photo_group_provider.dart';
import '../../template/presentation/template_provider.dart';

/// Detalle público de una publicación/grupo de ofertas (`/p/:slug`).
class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubs = ref.watch(marketplaceProvider);
    ListingDraft? pub;
    try {
      pub = pubs.firstWhere((d) => d.slug == slug && d.isActive);
    } catch (_) {
      pub = null;
    }

    final inventory = ref.watch(inventoryProvider);
    final groups = ref.watch(photoGroupProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final share =
        ref.read(publicBaseUrlProvider.notifier).shareUrlForSlug(slug);

    if (pub == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oferta')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Publicación no encontrada o archivada'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/tienda'),
                child: const Text('Ir a la tienda'),
              ),
            ],
          ),
        ),
      );
    }

    final products = inventory
        .where((p) => pub!.allProductIds.contains(p.id))
        .toList();
    final images = <String>[...pub.allImages];
    if (pub.photoGroupId != null) {
      try {
        final g = groups.firstWhere((x) => x.id == pub!.photoGroupId);
        images.insertAll(0, g.photoPaths);
      } catch (_) {}
    }
    final seen = <String>{};
    final uniqueImgs = [for (final p in images) if (seen.add(p)) p];

    return Scaffold(
      appBar: AppBar(
        title: Text(pub.title),
        actions: [
          TextButton(
            onPressed: () {
              final loggedIn = ref.read(authProvider).isAuthenticated;
              context.go(loggedIn ? '/inventario' : '/login');
            },
            child: Text(
              ref.watch(authProvider).isAuthenticated ? 'Admin' : 'Entrar',
            ),
          ),
          IconButton(
            tooltip: 'Copiar enlace de oferta',
            icon: const Icon(Icons.link),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: share));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enlace copiado: $share')),
              );
            },
          ),
          IconButton(
            tooltip: 'Exportar como borrador Marketplace',
            icon: const Icon(Icons.content_copy),
            onPressed: () async {
              final text = ref.read(marketplaceProvider.notifier).exportMarketplaceText(
                    publication: pub!,
                    products: inventory,
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
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (uniqueImgs.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: uniqueImgs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LocalImage(
                    path: uniqueImgs[i],
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Desde ${currency.format(pub.price)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${products.length} producto(s) en esta oferta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (pub.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(pub.description),
          ],
          const SizedBox(height: 20),
          Text(
            'Productos incluidos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...products.map(
            (Product p) => Card(
              child: ListTile(
                leading: p.primaryPhoto != null
                    ? LocalImage(
                        path: p.primaryPhoto!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.backpack),
                title: Text(p.name),
                subtitle: Text(
                  '${currency.format(p.price)} · ${p.condition.labelEs}'
                  '${p.colors.isEmpty ? '' : ' · ${p.colors.join(", ")}'}'
                  '\nStock ${p.stock}'
                  '${p.material.isEmpty ? '' : ' · ${p.material}'}',
                ),
                isThreeLine: true,
                onTap: () => context.push('/producto/${p.id}'),
              ),
            ),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Los productos de esta oferta ya no están en inventario.',
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/tienda'),
            icon: const Icon(Icons.storefront),
            label: const Text('Ver tienda de mochilas'),
          ),
        ],
      ),
    );
  }
}
