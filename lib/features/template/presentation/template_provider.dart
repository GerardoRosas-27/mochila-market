import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/template_repository.dart';
import '../../../core/models/marketplace_template.dart';

class TemplateNotifier extends StateNotifier<MarketplaceTemplate> {
  TemplateNotifier(this._repo) : super(const MarketplaceTemplate()) {
    _load();
  }

  final TemplateRepository _repo;

  Future<void> _load() async {
    state = await _repo.get();
  }

  Future<void> save(MarketplaceTemplate template) async {
    await _repo.save(template);
    state = template;
  }
}

final templateProvider =
    StateNotifierProvider<TemplateNotifier, MarketplaceTemplate>((ref) {
  return TemplateNotifier(ref.watch(templateRepositoryProvider));
});
