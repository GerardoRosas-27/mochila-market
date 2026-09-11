import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/ai_settings.dart';
import '../../../core/storage/secure_store.dart';

class AiSettingsNotifier extends StateNotifier<AiSettings> {
  AiSettingsNotifier(this._store) : super(const AiSettings()) {
    _load();
  }

  final SecureStore _store;
  static const _prefsKey = 'ai_settings_public';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    var next = const AiSettings();
    if (raw != null) {
      try {
        next = AiSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    final imageKey = await _store.readImageApiKey() ?? '';
    final multiKey = await _store.readMultimodalApiKey() ?? '';
    final removeKey = await _store.readRemoveBgApiKey() ?? '';
    state = next.copyWith(
      imageApiKey: imageKey,
      multimodalApiKey: multiKey,
      removeBgApiKey: removeKey,
    );
  }

  Future<void> save(AiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
    await _store.saveImageApiKey(settings.imageApiKey);
    await _store.saveMultimodalApiKey(settings.multimodalApiKey);
    await _store.saveRemoveBgApiKey(settings.removeBgApiKey);
    state = settings;
  }

  void updateLocal(AiSettings settings) {
    state = settings;
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AiSettingsNotifier, AiSettings>((ref) {
  return AiSettingsNotifier(ref.watch(secureStoreProvider));
});
