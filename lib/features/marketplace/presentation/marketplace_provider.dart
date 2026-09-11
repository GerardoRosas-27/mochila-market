import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/draft_repository.dart';
import '../../../core/models/company_data.dart';
import '../../../core/models/listing_draft.dart';
import '../../../core/models/marketplace_template.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/slug.dart';
import '../../template/domain/marketplace_template_renderer.dart';

class MarketplaceNotifier extends StateNotifier<List<ListingDraft>> {
  MarketplaceNotifier(this._repo) : super(const []) {
    _load();
  }

  final DraftRepository _repo;
  final _uuid = const Uuid();
  final _renderer = const MarketplaceTemplateRenderer();

  Future<void> _load() async {
    state = await _repo.getAll();
  }

  Future<void> reload() async {
    state = await _repo.getAll();
  }

  Future<ListingDraft?> getBySlug(String slug) => _repo.getBySlug(slug);

  /// Crea una publicación = grupo de ofertas a partir de productos del inventario.
  Future<ListingDraft> createOfferGroup({
    required String title,
    required List<Product> products,
    String description = '',
    String? photoGroupId,
    List<String> extraImages = const [],
    MarketplaceTemplate? template,
    CompanyData? company,
  }) async {
    if (products.isEmpty) {
      throw ArgumentError('Selecciona al menos un producto');
    }
    final id = _uuid.v4();
    final ids = products.map((p) => p.id).toList();
    final prices = products.map((p) => p.price).toList()..sort();
    final minPrice = prices.first;
    final images = <String>[
      ...extraImages,
      for (final p in products) ...p.photoPaths,
    ];
    final seen = <String>{};
    final unique = [for (final p in images) if (seen.add(p)) p];

    var desc = description;
    if (desc.isEmpty && template != null) {
      final parts = <String>[];
      for (final p in products) {
        final rendered = _renderer.render(
          template: template,
          product: p,
          company: company,
        );
        parts.add('— ${rendered.title}\n${rendered.body}');
      }
      desc = parts.join('\n\n');
    }

    final draft = ListingDraft(
      id: id,
      title: title.trim().isEmpty
          ? 'Oferta (${products.length} mochilas)'
          : title.trim(),
      price: minPrice,
      description: desc,
      imagePath: unique.isNotEmpty ? unique.first : null,
      imagePaths: unique,
      productId: ids.first,
      productIds: ids,
      photoGroupId: photoGroupId,
      marketplace: 'local',
      status: ListingStatus.activa,
      createdAt: DateTime.now(),
      slug: slugify(
        title.trim().isEmpty ? products.first.name : title.trim(),
        id,
      ),
    );
    await _repo.upsert(draft);
    await reload();
    return draft;
  }

  Future<ListingDraft> create({
    required String title,
    required double price,
    required String description,
    String? imagePath,
    List<String> imagePaths = const [],
    String? productId,
    List<String> productIds = const [],
    String? photoGroupId,
    String marketplace = 'local',
  }) async {
    final images = imagePaths.isNotEmpty
        ? imagePaths
        : (imagePath != null ? [imagePath] : <String>[]);
    final id = _uuid.v4();
    final ids = <String>[
      ...productIds,
      if (productId != null && productId.isNotEmpty) productId,
    ];
    final draft = ListingDraft(
      id: id,
      title: title,
      price: price,
      description: description,
      imagePath: images.isNotEmpty ? images.first : imagePath,
      imagePaths: images,
      productId: ids.isNotEmpty ? ids.first : productId,
      productIds: ids,
      photoGroupId: photoGroupId,
      marketplace: marketplace,
      status: ListingStatus.activa,
      createdAt: DateTime.now(),
      slug: slugify(title, id),
    );
    await _repo.upsert(draft);
    await reload();
    return draft;
  }

  /// Texto de plantilla Marketplace para pegar (exportar como borrador).
  String exportMarketplaceText({
    required ListingDraft publication,
    required List<Product> products,
    required MarketplaceTemplate template,
    CompanyData? company,
  }) {
    final linked = products
        .where((p) => publication.allProductIds.contains(p.id))
        .toList();
    if (linked.isEmpty) {
      return '${publication.title}\n\n${publication.description}\n\n'
          'Precio desde: \$${publication.price.toStringAsFixed(0)} MXN';
    }
    final buf = StringBuffer();
    buf.writeln(publication.title);
    buf.writeln();
    if (publication.description.trim().isNotEmpty) {
      buf.writeln(publication.description.trim());
      buf.writeln();
    }
    for (final p in linked) {
      final r = _renderer.render(
        template: template,
        product: p,
        company: company,
      );
      buf.writeln('———');
      buf.writeln(r.title);
      buf.writeln(r.body);
      buf.writeln();
    }
    return buf.toString().trim();
  }

  Future<void> updateDraft(ListingDraft draft) async {
    final withSlug = draft.slug.isEmpty
        ? draft.copyWith(slug: slugify(draft.title, draft.id))
        : draft;
    await _repo.upsert(withSlug);
    await reload();
  }

  Future<void> updateStatus(String id, ListingStatus status) async {
    final current = state.where((d) => d.id == id).toList();
    if (current.isEmpty) return;
    await _repo.upsert(current.first.copyWith(status: status));
    await reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await reload();
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, List<ListingDraft>>((ref) {
  return MarketplaceNotifier(ref.watch(draftRepositoryProvider));
});
