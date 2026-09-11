import '../../models/company_data.dart';

abstract class CompanyRepository {
  Future<CompanyData> get();
  Future<void> save(CompanyData data);
}
