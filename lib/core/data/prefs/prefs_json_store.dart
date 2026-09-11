import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/company_data.dart';
import '../../models/listing_draft.dart';
import '../../models/marketplace_template.dart';
import '../../models/photo_group.dart';
import '../../models/product.dart';
import '../../utils/slug.dart';
import '../repositories/company_repository.dart';
import '../repositories/draft_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/photo_group_repository.dart';
import '../repositories/template_repository.dart';

/// Persistencia JSON en SharedPreferences (Flutter web / Railway SPA).
class PrefsJsonStore {
  PrefsJsonStore._();
  static final PrefsJsonStore instance = PrefsJsonStore._();

  static const _kProducts = 'web_products_v1';
  static const _kDrafts = 'web_publications_v1';
  static const _kGroups = 'web_photo_groups_v1';
  static const _kTemplate = 'web_template_v1';
  static const _kCompany = 'web_company_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    await (await _prefs).setString(key, jsonEncode(list));
  }

  Future<List<Product>> getProducts() async {
    final list = await _readList(_kProducts);
    return list.map(Product.fromJson).toList();
  }

  Future<void> upsertProduct(Product p) async {
    final list = await getProducts();
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    await _writeList(_kProducts, list.map((e) => e.toJson()).toList());
  }

  Future<void> deleteProduct(String id) async {
    final list = await getProducts();
    list.removeWhere((x) => x.id == id);
    await _writeList(_kProducts, list.map((e) => e.toJson()).toList());
  }

  Future<List<ListingDraft>> getDrafts() async {
    final list = await _readList(_kDrafts);
    return list.map((j) {
      final d = ListingDraft.fromJson(j);
      if (d.slug.isEmpty) {
        return d.copyWith(slug: slugify(d.title, d.id));
      }
      return d;
    }).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bc = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bc.compareTo(ac);
      });
  }

  Future<void> upsertDraft(ListingDraft d) async {
    final withSlug = d.slug.isEmpty
        ? d.copyWith(slug: slugify(d.title, d.id))
        : d;
    final list = await getDrafts();
    final i = list.indexWhere((x) => x.id == withSlug.id);
    if (i >= 0) {
      list[i] = withSlug;
    } else {
      list.add(withSlug);
    }
    await _writeList(_kDrafts, list.map((e) => e.toJson()).toList());
  }

  Future<void> deleteDraft(String id) async {
    final list = await getDrafts();
    list.removeWhere((x) => x.id == id);
    await _writeList(_kDrafts, list.map((e) => e.toJson()).toList());
  }

  Future<List<PhotoGroup>> getGroups() async {
    final list = await _readList(_kGroups);
    return list.map(PhotoGroup.fromJson).toList();
  }

  Future<void> upsertGroup(PhotoGroup g) async {
    final list = await getGroups();
    final i = list.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      list[i] = g;
    } else {
      list.add(g);
    }
    await _writeList(_kGroups, list.map((e) => e.toJson()).toList());
  }

  Future<void> deleteGroup(String id) async {
    final list = await getGroups();
    list.removeWhere((x) => x.id == id);
    await _writeList(_kGroups, list.map((e) => e.toJson()).toList());
  }

  Future<MarketplaceTemplate> getTemplate() async {
    final raw = (await _prefs).getString(_kTemplate);
    if (raw == null) return const MarketplaceTemplate();
    try {
      return MarketplaceTemplate.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const MarketplaceTemplate();
    }
  }

  Future<void> saveTemplate(MarketplaceTemplate t) async {
    await (await _prefs).setString(_kTemplate, jsonEncode(t.toJson()));
  }

  Future<CompanyData> getCompany() async {
    final raw = (await _prefs).getString(_kCompany);
    if (raw == null) return const CompanyData();
    try {
      return CompanyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CompanyData();
    }
  }

  Future<void> saveCompany(CompanyData c) async {
    await (await _prefs).setString(_kCompany, jsonEncode(c.toJson()));
  }
}

class PrefsInventoryRepository implements InventoryRepository {
  PrefsInventoryRepository(this._store);
  final PrefsJsonStore _store;

  @override
  Future<List<Product>> getAll() => _store.getProducts();

  @override
  Future<Product?> getById(String id) async {
    final all = await _store.getProducts();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsert(Product product) => _store.upsertProduct(product);

  @override
  Future<void> delete(String id) => _store.deleteProduct(id);
}

class PrefsDraftRepository implements DraftRepository {
  PrefsDraftRepository(this._store);
  final PrefsJsonStore _store;

  @override
  Future<List<ListingDraft>> getAll() => _store.getDrafts();

  @override
  Future<ListingDraft?> getById(String id) async {
    final all = await _store.getDrafts();
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ListingDraft?> getBySlug(String slug) async {
    final all = await _store.getDrafts();
    try {
      return all.firstWhere((d) => d.slug == slug);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsert(ListingDraft draft) => _store.upsertDraft(draft);

  @override
  Future<void> delete(String id) => _store.deleteDraft(id);
}

class PrefsPhotoGroupRepository implements PhotoGroupRepository {
  PrefsPhotoGroupRepository(this._store);
  final PrefsJsonStore _store;

  @override
  Future<List<PhotoGroup>> getAll() => _store.getGroups();

  @override
  Future<PhotoGroup?> getById(String id) async {
    final all = await _store.getGroups();
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsert(PhotoGroup group) => _store.upsertGroup(group);

  @override
  Future<void> delete(String id) => _store.deleteGroup(id);
}

class PrefsTemplateRepository implements TemplateRepository {
  PrefsTemplateRepository(this._store);
  final PrefsJsonStore _store;

  @override
  Future<MarketplaceTemplate> get() => _store.getTemplate();

  @override
  Future<void> save(MarketplaceTemplate template) =>
      _store.saveTemplate(template);
}

class PrefsCompanyRepository implements CompanyRepository {
  PrefsCompanyRepository(this._store);
  final PrefsJsonStore _store;

  @override
  Future<CompanyData> get() => _store.getCompany();

  @override
  Future<void> save(CompanyData data) => _store.saveCompany(data);
}
