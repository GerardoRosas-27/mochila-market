import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/company_data.dart';
import '../database/app_database.dart';
import '../repositories/company_repository.dart';

class SqliteCompanyRepository implements CompanyRepository {
  SqliteCompanyRepository(this._db);
  final AppDatabase _db;

  @override
  Future<CompanyData> get() async {
    final db = await _db.database;
    final rows = await db.query(
      'company_data',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return const CompanyData();
    try {
      return CompanyData.fromJson(
        jsonDecode(rows.first['payload_json'] as String)
            as Map<String, dynamic>,
      );
    } catch (_) {
      return const CompanyData();
    }
  }

  @override
  Future<void> save(CompanyData data) async {
    final db = await _db.database;
    await db.insert(
      'company_data',
      {
        'id': 1,
        'payload_json': jsonEncode(data.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
