import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/backpack.dart';
import '../data/seed_backpacks.dart';

class CatalogNotifier extends StateNotifier<List<Backpack>> {
  CatalogNotifier() : super(seedBackpacks());

  final _uuid = const Uuid();

  void add(Backpack item) {
    state = [...state, item];
  }

  void update(Backpack item) {
    state = [
      for (final b in state)
        if (b.id == item.id) item else b,
    ];
  }

  void remove(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  Backpack createDraft({
    String name = '',
    String brand = '',
    double price = 0,
    String description = '',
    String category = 'mochila',
    int stock = 1,
  }) {
    return Backpack(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      price: price,
      description: description,
      category: category,
      stock: stock,
    );
  }
}

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, List<Backpack>>((ref) {
  return CatalogNotifier();
});
