import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/listing_draft.dart';

class MarketplaceNotifier extends StateNotifier<List<ListingDraft>> {
  MarketplaceNotifier() : super(const []);

  final _uuid = const Uuid();

  void addDraft(ListingDraft draft) {
    state = [draft, ...state];
  }

  ListingDraft create({
    required String title,
    required double price,
    required String description,
    String? imagePath,
    String marketplace = 'demo',
  }) {
    final draft = ListingDraft(
      id: _uuid.v4(),
      title: title,
      price: price,
      description: description,
      imagePath: imagePath,
      marketplace: marketplace,
      status: ListingStatus.borrador,
      createdAt: DateTime.now(),
    );
    addDraft(draft);
    return draft;
  }

  void updateStatus(String id, ListingStatus status) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(status: status) else d,
    ];
  }

  void remove(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, List<ListingDraft>>((ref) {
  return MarketplaceNotifier();
});
