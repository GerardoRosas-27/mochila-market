import 'package:sqflite/sqflite.dart';

import '../../models/product.dart';
import '../database/app_database.dart';
import '../repositories/inventory_repository.dart';

class SqliteInventoryRepository implements InventoryRepository {
  SqliteInventoryRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<Product>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE');
    return rows.map(AppDatabase.productFromRow).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppDatabase.productFromRow(rows.first);
  }

  @override
  Future<void> upsert(Product product) async {
    final db = await _db.database;
    await db.insert(
      'products',
      AppDatabase.productToRow(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
