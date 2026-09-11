import 'package:sqflite/sqflite.dart';

import '../../models/photo_group.dart';
import '../database/app_database.dart';
import '../repositories/photo_group_repository.dart';

class SqlitePhotoGroupRepository implements PhotoGroupRepository {
  SqlitePhotoGroupRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<PhotoGroup>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'photo_groups',
      orderBy: 'created_at DESC',
    );
    return rows.map(AppDatabase.photoGroupFromRow).toList();
  }

  @override
  Future<PhotoGroup?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'photo_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppDatabase.photoGroupFromRow(rows.first);
  }

  @override
  Future<void> upsert(PhotoGroup group) async {
    final db = await _db.database;
    await db.insert(
      'photo_groups',
      AppDatabase.photoGroupToRow(group),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('photo_groups', where: 'id = ?', whereArgs: [id]);
  }
}
