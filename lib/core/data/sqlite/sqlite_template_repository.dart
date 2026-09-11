import 'package:sqflite/sqflite.dart';

import '../../models/marketplace_template.dart';
import '../database/app_database.dart';
import '../repositories/template_repository.dart';

class SqliteTemplateRepository implements TemplateRepository {
  SqliteTemplateRepository(this._db);
  final AppDatabase _db;

  @override
  Future<MarketplaceTemplate> get() async {
    final db = await _db.database;
    final rows = await db.query(
      'marketplace_template',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return const MarketplaceTemplate();
    final row = rows.first;
    return MarketplaceTemplate(
      titleTemplate:
          row['title_template'] as String? ?? MarketplaceTemplate.defaultTitle,
      bodyTemplate:
          row['body_template'] as String? ?? MarketplaceTemplate.defaultBody,
    );
  }

  @override
  Future<void> save(MarketplaceTemplate template) async {
    final db = await _db.database;
    await db.insert(
      'marketplace_template',
      {
        'id': 1,
        'title_template': template.titleTemplate,
        'body_template': template.bodyTemplate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
