import 'package:sqflite/sqflite.dart';

import '../../models/listing_draft.dart';
import '../database/app_database.dart';
import '../repositories/draft_repository.dart';

class SqliteDraftRepository implements DraftRepository {
  SqliteDraftRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<ListingDraft>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'listing_drafts',
      orderBy: 'created_at DESC',
    );
    return rows.map(AppDatabase.draftFromRow).toList();
  }

  @override
  Future<ListingDraft?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'listing_drafts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppDatabase.draftFromRow(rows.first);
  }

  @override
  Future<ListingDraft?> getBySlug(String slug) async {
    final db = await _db.database;
    final rows = await db.query(
      'listing_drafts',
      where: 'slug = ?',
      whereArgs: [slug],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppDatabase.draftFromRow(rows.first);
  }

  @override
  Future<void> upsert(ListingDraft draft) async {
    final db = await _db.database;
    await db.insert(
      'listing_drafts',
      AppDatabase.draftToRow(draft),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('listing_drafts', where: 'id = ?', whereArgs: [id]);
  }
}
