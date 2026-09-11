import '../../models/product.dart';

abstract class InventoryRepository {
  Future<List<Product>> getAll();
  Future<Product?> getById(String id);
  Future<void> upsert(Product product);
  Future<void> delete(String id);
}
