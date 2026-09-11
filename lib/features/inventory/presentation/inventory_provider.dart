import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/inventory_repository.dart';
import '../../../core/models/product.dart';
import '../data/seed_products.dart';

class InventoryNotifier extends StateNotifier<List<Product>> {
  InventoryNotifier(this._repo) : super(const []) {
    _load();
  }

  final InventoryRepository _repo;
  final _uuid = const Uuid();

  Future<void> _load() async {
    var list = await _repo.getAll();
    if (list.isEmpty) {
      final seeds = seedProducts();
      for (final p in seeds) {
        await _repo.upsert(p);
      }
      list = await _repo.getAll();
    }
    state = list;
  }

  Future<void> reload() async {
    state = await _repo.getAll();
  }

  Future<void> add(Product item) async {
    await _repo.upsert(item);
    await reload();
  }

  Future<void> update(Product item) async {
    await _repo.upsert(item);
    await reload();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    await reload();
  }

  Product createDraft() {
    return Product(
      id: _uuid.v4(),
      name: '',
      price: 0,
    );
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<Product>>((ref) {
  return InventoryNotifier(ref.watch(inventoryRepositoryProvider));
});

/// Alias: el catálogo fino se reemplaza por inventario.
final catalogProvider = inventoryProvider;
