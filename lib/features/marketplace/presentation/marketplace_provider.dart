import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/draft_repository.dart';
import '../../../core/models/company_data.dart';
import '../../../core/models/listing_draft.dart';
import '../../../core/models/marketplace_template.dart';
import '../../../core/models/product.dart';
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

  Future<ListingDraft> create({
    required String title,
    required double price,
    required String description,
    String? imagePath,
    List<String> imagePaths = const [],
    String? productId,
    String? photoGroupId,
    String marketplace = 'local',
  }) async {
    final images = imagePaths.isNotEmpty
        ? imagePaths
        : (imagePath != null ? [imagePath] : <String>[]);
    final draft = ListingDraft(
      id: _uuid.v4(),
      title: title,
      price: price,
      description: description,
      imagePath: images.isNotEmpty ? images.first : imagePath,
      imagePaths: images,
      productId: productId,
      photoGroupId: photoGroupId,
      marketplace: marketplace,
      status: ListingStatus.borrador,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(draft);
    await reload();
    return draft;
  }

  Future<ListingDraft> createFromProduct({
    required Product product,
    required MarketplaceTemplate template,
    CompanyData? company,
    String? photoGroupId,
    List<String>? extraImages,
  }) async {
    final rendered = _renderer.render(
      template: template,
      product: product,
      company: company,
    );
    final images = <String>[
      ...?extraImages,
      ...product.photoPaths,
    ];
    // dedupe keep order
    final seen = <String>{};
    final unique = <String>[];
    for (final p in images) {
      if (seen.add(p)) unique.add(p);
    }
    return create(
      title: rendered.title.isEmpty ? product.name : rendered.title,
      price: product.price,
      description: rendered.body,
      imagePaths: unique,
      productId: product.id,
      photoGroupId: photoGroupId,
      marketplace: 'local',
    );
  }

  Future<void> updateDraft(ListingDraft draft) async {
    await _repo.upsert(draft);
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
