import '../../models/company_data.dart';
import '../../models/listing_draft.dart';
import '../../models/marketplace_template.dart';
import '../../models/photo_group.dart';
import '../../models/product.dart';

/// Stub para futura sincronización con Postgres en la nube.
///
/// El mapeo SQLite → Postgres está documentado en el README.
/// No realiza llamadas de red todavía.
class CloudRepository {
  CloudRepository({this.connectionString});

  /// Ejemplo futuro: `postgres://user:pass@host:5432/mochila`
  final String? connectionString;

  Never _todo(String op) => throw UnimplementedError(
        'CloudRepository/$op: migrar a Postgres (ver README). '
        'connectionString=${connectionString ?? "(vacío)"}',
      );

  Future<List<Product>> fetchProducts() async => _todo('fetchProducts');
  Future<void> pushProduct(Product product) async => _todo('pushProduct');

  Future<List<ListingDraft>> fetchDrafts() async => _todo('fetchDrafts');
  Future<void> pushDraft(ListingDraft draft) async => _todo('pushDraft');

  Future<List<PhotoGroup>> fetchPhotoGroups() async =>
      _todo('fetchPhotoGroups');
  Future<void> pushPhotoGroup(PhotoGroup group) async =>
      _todo('pushPhotoGroup');

  Future<MarketplaceTemplate> fetchTemplate() async => _todo('fetchTemplate');
  Future<void> pushTemplate(MarketplaceTemplate template) async =>
      _todo('pushTemplate');

  Future<CompanyData> fetchCompany() async => _todo('fetchCompany');
  Future<void> pushCompany(CompanyData data) async => _todo('pushCompany');
}
