import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ai_settings.dart';
import '../../../core/storage/secure_store.dart';
import '../../ai_settings/presentation/ai_settings_provider.dart';
import '../domain/bg_remover.dart';
import 'demo_bg_remover.dart';
import 'generic_http_bg_remover.dart';
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
        final key =
            await store.readRemoveBgApiKey() ?? settings.removeBgApiKey;
        return RemoveBgHttpRemover(apiKey: key);
      case BgProvider.genericHttp:
        final key = await store.readImageApiKey() ?? settings.imageApiKey;
        final endpoint = settings.genericBgEndpoint.trim().isNotEmpty
            ? settings.genericBgEndpoint.trim()
            : _join(settings.imageApiBaseUrl, 'remove-bg');
        return GenericHttpBgRemover(
          endpoint: endpoint,
          apiKey: key,
          model: settings.imageModel,
        );
    }
  }

  String _join(String base, String path) {
    if (base.isEmpty) return path;
    return base.endsWith('/') ? '$base$path' : '$base/$path';
  }

  Future<Uint8List> remove(Uint8List bytes) async {
    final remover = await resolve();
    return remover.removeBackground(bytes);
  }
}
