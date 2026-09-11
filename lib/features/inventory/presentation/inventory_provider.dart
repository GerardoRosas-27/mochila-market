import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/product.dart';
import '../data/seed_products.dart';

class InventoryNotifier extends StateNotifier<List<Product>> {
  InventoryNotifier() : super(const []) {
    _load();
  }

  final _uuid = const Uuid();
  static const _prefsKey = 'inventory_products_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList();
        state = list;
        return;
      } catch (_) {}
    }
    // Migración: catálogo semilla antiguo (Backpack) → Product
    final legacy = prefs.getString('catalog_backpacks');
    if (legacy != null) {
      try {
        final list = (jsonDecode(legacy) as List)
            .cast<Map<String, dynamic>>()
            .map(Product.fromBackpackJson)
            .toList();
        state = list;
        await _persist();
        return;
      } catch (_) {}
    }
    state = seedProducts();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(Product item) async {
    state = [...state, item];
    await _persist();
  }

  Future<void> update(Product item) async {
    state = [
      for (final b in state)
        if (b.id == item.id) item else b,
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((b) => b.id != id).toList();
    await _persist();
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
  return InventoryNotifier();
});

/// Alias: el catálogo fino se reemplaza por inventario.
final catalogProvider = inventoryProvider;
