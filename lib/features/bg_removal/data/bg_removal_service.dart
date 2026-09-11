import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ai_settings.dart';
import '../../../core/storage/secure_store.dart';
import '../../ai_settings/presentation/ai_settings_provider.dart';
import '../domain/bg_remover.dart';
import 'demo_bg_remover.dart';
import 'remove_bg_http_remover.dart';

final bgRemovalServiceProvider = Provider<BgRemovalService>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  final store = ref.watch(secureStoreProvider);
  return BgRemovalService(settings: settings, store: store);
});

class BgRemovalService {
  BgRemovalService({required this.settings, required this.store});

  final AiSettings settings;
  final SecureStore store;

  Future<BgRemover> resolve() async {
    switch (settings.bgProvider) {
      case BgProvider.demo:
        return DemoBgRemover();
      case BgProvider.removeBg:
        final key = await store.readRemoveBgApiKey() ?? settings.removeBgApiKey;
        return RemoveBgHttpRemover(apiKey: key);
    }
  }

  Future<Uint8List> remove(Uint8List bytes) async {
    final remover = await resolve();
    return remover.removeBackground(bytes);
  }
}
