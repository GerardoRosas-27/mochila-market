import '../../models/marketplace_template.dart';

abstract class TemplateRepository {
  Future<MarketplaceTemplate> get();
  Future<void> save(MarketplaceTemplate template);
}
