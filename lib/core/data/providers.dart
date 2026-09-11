import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud/cloud_repository_stub.dart';
import 'database/app_database.dart';
import 'repositories/company_repository.dart';
import 'repositories/draft_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/photo_group_repository.dart';
import 'repositories/template_repository.dart';
import 'sqlite/sqlite_company_repository.dart';
import 'sqlite/sqlite_draft_repository.dart';
import 'sqlite/sqlite_inventory_repository.dart';
import 'sqlite/sqlite_photo_group_repository.dart';
import 'sqlite/sqlite_template_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return SqliteInventoryRepository(ref.watch(appDatabaseProvider));
});

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return SqliteDraftRepository(ref.watch(appDatabaseProvider));
});

final photoGroupRepositoryProvider = Provider<PhotoGroupRepository>((ref) {
  return SqlitePhotoGroupRepository(ref.watch(appDatabaseProvider));
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return SqliteTemplateRepository(ref.watch(appDatabaseProvider));
});

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return SqliteCompanyRepository(ref.watch(appDatabaseProvider));
});

/// Stub opcional para migración futura a Postgres (no operativo).
final cloudRepositoryProvider = Provider<CloudRepository>((ref) {
  return CloudRepository();
});
