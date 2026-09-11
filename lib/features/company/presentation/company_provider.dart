import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/providers.dart';
import '../../../core/data/repositories/company_repository.dart';
import '../../../core/models/company_data.dart';

class CompanyNotifier extends StateNotifier<CompanyData> {
  CompanyNotifier(this._repo) : super(const CompanyData()) {
    _load();
  }

  final CompanyRepository _repo;

  Future<void> _load() async {
    state = await _repo.get();
  }

  Future<void> save(CompanyData data) async {
    await _repo.save(data);
    state = data;
  }
}

final companyProvider =
    StateNotifierProvider<CompanyNotifier, CompanyData>((ref) {
  return CompanyNotifier(ref.watch(companyRepositoryProvider));
});
