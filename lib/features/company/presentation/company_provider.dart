import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/company_data.dart';

class CompanyNotifier extends StateNotifier<CompanyData> {
  CompanyNotifier() : super(const CompanyData()) {
    _load();
  }

  static const _prefsKey = 'company_data_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        state = CompanyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> save(CompanyData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data.toJson()));
    state = data;
  }
}

final companyProvider =
    StateNotifierProvider<CompanyNotifier, CompanyData>((ref) {
  return CompanyNotifier();
});
