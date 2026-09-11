import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/company_data.dart';
import '../../models/listing_draft.dart';
import '../../models/marketplace_template.dart';
import '../../models/product.dart';
import '../../models/photo_group.dart';
import '../../utils/slug.dart';

/// SQLite local (móvil/escritorio). En web se usa [PrefsJsonStore].
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  bool _migratedPrefs = false;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite no está disponible en web; usa PrefsJsonStore.',
      );
    }
    if (_db != null) return _db!;
    _db = await _open();
    if (!_migratedPrefs) {
      await _migrateFromSharedPreferences(_db!);
      _migratedPrefs = true;
    }
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'mochila_market.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createV1(db);
        await _upgradeToV2(db);
        await _upgradeToV3(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _upgradeToV2(db);
        if (oldVersion < 3) await _upgradeToV3(db);
      },
    );
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
CREATE TABLE products (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  stock INTEGER NOT NULL DEFAULT 1,
  available INTEGER NOT NULL DEFAULT 1,
  colors_json TEXT NOT NULL DEFAULT '[]',
  sizes_json TEXT NOT NULL DEFAULT '[]',
  material TEXT NOT NULL DEFAULT '',
  brand TEXT NOT NULL DEFAULT '',
  condition TEXT NOT NULL DEFAULT 'nuevo',
  tags_json TEXT NOT NULL DEFAULT '[]',
  photo_paths_json TEXT NOT NULL DEFAULT '[]',
  location_override TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'mochila'
)''');
    await db.execute('''
CREATE TABLE listing_drafts (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  price REAL NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  image_path TEXT,
  image_paths_json TEXT NOT NULL DEFAULT '[]',
  product_id TEXT,
  photo_group_id TEXT,
  marketplace TEXT NOT NULL DEFAULT 'local',
  status TEXT NOT NULL DEFAULT 'activa',
  created_at TEXT,
  slug TEXT NOT NULL DEFAULT '',
  product_ids_json TEXT NOT NULL DEFAULT '[]'
)''');
    await db.execute('''
CREATE TABLE photo_groups (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  photo_paths_json TEXT NOT NULL DEFAULT '[]',
  created_at TEXT
)''');
    await db.execute('''
CREATE TABLE marketplace_template (
  id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
  title_template TEXT NOT NULL,
  body_template TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE company_data (
  id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
  payload_json TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
)''');
    await db.insert('marketplace_template', {
      'id': 1,
      'title_template': MarketplaceTemplate.defaultTitle,
      'body_template': MarketplaceTemplate.defaultBody,
    });
    await db.insert('company_data', {
      'id': 1,
      'payload_json': jsonEncode(const CompanyData().toJson()),
    });
  }

  Future<void> _upgradeToV2(Database db) async {
    try {
      await db.execute(
        "ALTER TABLE listing_drafts ADD COLUMN slug TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {}
    final rows = await db.query('listing_drafts');
    for (final row in rows) {
      final id = row['id'] as String;
      final title = row['title'] as String? ?? '';
      final existing = row['slug'] as String? ?? '';
      if (existing.isEmpty) {
        await db.update(
          'listing_drafts',
          {'slug': slugify(title, id)},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    await db.rawUpdate(
      "UPDATE listing_drafts SET status = 'activa' "
      "WHERE status IN ('borrador', 'publicado')",
    );
  }

  Future<void> _upgradeToV3(Database db) async {
    try {
      await db.execute(
        "ALTER TABLE listing_drafts ADD COLUMN product_ids_json "
        "TEXT NOT NULL DEFAULT '[]'",
      );
    } catch (_) {}
    final rows = await db.query('listing_drafts');
    for (final row in rows) {
      final id = row['id'] as String;
      final raw = row['product_ids_json'] as String? ?? '[]';
      final legacy = row['product_id'] as String?;
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        if (list.isEmpty && legacy != null && legacy.isNotEmpty) {
          await db.update(
            'listing_drafts',
            {'product_ids_json': jsonEncode([legacy])},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      } catch (_) {
        if (legacy != null && legacy.isNotEmpty) {
          await db.update(
            'listing_drafts',
            {'product_ids_json': jsonEncode([legacy])},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    }
  }

  Future<void> _migrateFromSharedPreferences(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('sqlite_migrated_v1') ?? false;
    if (flag) return;

    final productsRaw = prefs.getString('inventory_products_v1');
    if (productsRaw != null) {
      try {
        final list = (jsonDecode(productsRaw) as List)
            .cast<Map<String, dynamic>>()
            .map(Product.fromJson);
        final existing = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM products'),
            ) ??
            0;
        if (existing == 0) {
          final batch = db.batch();
          for (final p in list) {
            batch.insert('products', _productRow(p));
          }
          await batch.commit(noResult: true);
        }
      } catch (_) {}
    } else {
      final legacy = prefs.getString('catalog_backpacks');
      if (legacy != null) {
        try {
          final list = (jsonDecode(legacy) as List)
              .cast<Map<String, dynamic>>()
              .map(Product.fromBackpackJson);
          final existing = Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM products'),
              ) ??
              0;
          if (existing == 0) {
            final batch = db.batch();
            for (final p in list) {
              batch.insert('products', _productRow(p));
            }
            await batch.commit(noResult: true);
          }
        } catch (_) {}
      }
    }

    final draftsRaw = prefs.getString('marketplace_drafts_v1');
    if (draftsRaw != null) {
      try {
        final list = (jsonDecode(draftsRaw) as List)
            .cast<Map<String, dynamic>>()
            .map(ListingDraft.fromJson);
        final existing = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM listing_drafts'),
            ) ??
            0;
        if (existing == 0) {
          final batch = db.batch();
          for (final d in list) {
            batch.insert('listing_drafts', _draftRow(d));
          }
          await batch.commit(noResult: true);
        }
      } catch (_) {}
    }

    final companyRaw = prefs.getString('company_data_v1');
    if (companyRaw != null) {
      try {
        await db.update(
          'company_data',
          {'payload_json': companyRaw},
          where: 'id = ?',
          whereArgs: [1],
        );
      } catch (_) {}
    }

    await prefs.setBool('sqlite_migrated_v1', true);
  }

  static Map<String, Object?> _productRow(Product p) => {
        'id': p.id,
        'name': p.name,
        'price': p.price,
        'description': p.description,
        'sku': p.sku,
        'stock': p.stock,
        'available': p.available ? 1 : 0,
        'colors_json': jsonEncode(p.colors),
        'sizes_json': jsonEncode(p.sizes),
        'material': p.material,
        'brand': p.brand,
        'condition': p.condition.name,
        'tags_json': jsonEncode(p.tags),
        'photo_paths_json': jsonEncode(p.photoPaths),
        'location_override': p.locationOverride,
        'category': p.category,
      };

  static Map<String, Object?> _draftRow(ListingDraft d) {
    final slug = d.slug.isNotEmpty ? d.slug : slugify(d.title, d.id);
    final ids = d.allProductIds;
    return {
      'id': d.id,
      'title': d.title,
      'price': d.price,
      'description': d.description,
      'image_path': d.imagePath,
      'image_paths_json': jsonEncode(d.imagePaths),
      'product_id': ids.isNotEmpty ? ids.first : d.productId,
      'product_ids_json': jsonEncode(ids),
      'photo_group_id': d.photoGroupId,
      'marketplace': d.marketplace,
      'status': d.status.name,
      'created_at': d.createdAt?.toIso8601String(),
      'slug': slug,
    };
  }

  static Product productFromRow(Map<String, Object?> row) {
    List<String> decodeList(Object? raw) {
      if (raw == null) return const [];
      try {
        return (jsonDecode(raw as String) as List).cast<String>();
      } catch (_) {
        return const [];
      }
    }

    return Product(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      price: (row['price'] as num?)?.toDouble() ?? 0,
      description: row['description'] as String? ?? '',
      sku: row['sku'] as String? ?? '',
      stock: row['stock'] as int? ?? 1,
      available: (row['available'] as int? ?? 1) == 1,
      colors: decodeList(row['colors_json']),
      sizes: decodeList(row['sizes_json']),
      material: row['material'] as String? ?? '',
      brand: row['brand'] as String? ?? '',
      condition: ProductCondition.values.firstWhere(
        (e) => e.name == row['condition'],
        orElse: () => ProductCondition.nuevo,
      ),
      tags: decodeList(row['tags_json']),
      photoPaths: decodeList(row['photo_paths_json']),
      locationOverride: row['location_override'] as String? ?? '',
      category: row['category'] as String? ?? 'mochila',
    );
  }

  static ListingDraft draftFromRow(Map<String, Object?> row) {
    List<String> decodeList(Object? raw) {
      if (raw == null) return const [];
      try {
        return (jsonDecode(raw as String) as List).cast<String>();
      } catch (_) {
        return const [];
      }
    }

    final id = row['id'] as String;
    final title = row['title'] as String? ?? '';
    var slug = row['slug'] as String? ?? '';
    if (slug.isEmpty) slug = slugify(title, id);

    final productIds = decodeList(row['product_ids_json']);
    final legacyPid = row['product_id'] as String?;
    final mergedIds = <String>[
      ...productIds,
      if (legacyPid != null &&
          legacyPid.isNotEmpty &&
          !productIds.contains(legacyPid))
        legacyPid,
    ];

    return ListingDraft(
      id: id,
      title: title,
      price: (row['price'] as num?)?.toDouble() ?? 0,
      description: row['description'] as String? ?? '',
      imagePath: row['image_path'] as String?,
      imagePaths: decodeList(row['image_paths_json']),
      productId: legacyPid,
      productIds: mergedIds,
      photoGroupId: row['photo_group_id'] as String?,
      marketplace: row['marketplace'] as String? ?? 'local',
      status: ListingDraft.fromJson({
        'id': id,
        'title': title,
        'price': 0,
        'status': row['status'],
      }).status,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
      slug: slug,
    );
  }

  static PhotoGroup photoGroupFromRow(Map<String, Object?> row) {
    List<String> decodeList(Object? raw) {
      if (raw == null) return const [];
      try {
        return (jsonDecode(raw as String) as List).cast<String>();
      } catch (_) {
        return const [];
      }
    }

    return PhotoGroup(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      photoPaths: decodeList(row['photo_paths_json']),
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }

  static Map<String, Object?> productToRow(Product p) => _productRow(p);
  static Map<String, Object?> draftToRow(ListingDraft d) => _draftRow(d);

  static Map<String, Object?> photoGroupToRow(PhotoGroup g) => {
        'id': g.id,
        'name': g.name,
        'photo_paths_json': jsonEncode(g.photoPaths),
        'created_at': g.createdAt?.toIso8601String(),
      };
}
