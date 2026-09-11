import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/listing_draft.dart';
import '../../../core/models/product.dart';

class MarketplaceNotifier extends StateNotifier<List<ListingDraft>> {
  MarketplaceNotifier() : super(const []) {
    _load();
  }

  final _uuid = const Uuid();
  static const _prefsKey = 'marketplace_drafts_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(ListingDraft.fromJson)
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addDraft(ListingDraft draft) {
    state = [draft, ...state];
    _persist();
  }

  ListingDraft create({
    required String title,
    required double price,
    required String description,
    String? imagePath,
    List<String> imagePaths = const [],
    String? productId,
    String marketplace = 'demo',
    PublishChannel publishChannel = PublishChannel.borradorLocal,
  }) {
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
      marketplace: marketplace,
      status: ListingStatus.borrador,
      createdAt: DateTime.now(),
      publishChannel: publishChannel,
    );
    addDraft(draft);
    return draft;
  }

  ListingDraft createFromProduct(Product p) {
    final buf = StringBuffer(p.description);
    if (p.brand.isNotEmpty) buf.writeln('\nMarca: ${p.brand}');
    if (p.sku.isNotEmpty) buf.writeln('SKU: ${p.sku}');
    if (p.colors.isNotEmpty) buf.writeln('Colores: ${p.colors.join(', ')}');
    if (p.sizes.isNotEmpty) buf.writeln('Tamaños: ${p.sizes.join(', ')}');
    if (p.material.isNotEmpty) buf.writeln('Material: ${p.material}');
    buf.writeln('Condición: ${p.condition.labelEs}');
    if (p.locationOverride.isNotEmpty) {
      buf.writeln('Ubicación: ${p.locationOverride}');
    }
    return create(
      title: p.name,
      price: p.price,
      description: buf.toString().trim(),
      imagePaths: p.photoPaths,
      productId: p.id,
      marketplace: 'page_feed',
      publishChannel: PublishChannel.borradorLocal,
    );
  }

  Future<void> updateDraft(ListingDraft draft) async {
    state = [
      for (final d in state)
        if (d.id == draft.id) draft else d,
    ];
    await _persist();
  }

  Future<void> updateStatus(String id, ListingStatus status) async {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(status: status) else d,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((d) => d.id != id).toList();
    await _persist();
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, List<ListingDraft>>((ref) {
  return MarketplaceNotifier();
});
