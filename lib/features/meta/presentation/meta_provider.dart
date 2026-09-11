import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/meta_config.dart';
import '../../../core/storage/secure_store.dart';
import '../data/meta_graph_service.dart';

final metaGraphServiceProvider = Provider<MetaGraphService>((ref) {
  return MetaGraphService();
});

class MetaNotifier extends StateNotifier<MetaConfig> {
  MetaNotifier(this._store, this._service) : super(const MetaConfig()) {
    _load();
  }

  final SecureStore _store;
  final MetaGraphService _service;
  static const _prefsKey = 'meta_config_public';

  List<MetaPageInfo> pages = [];
  String? lastActionMessage;
  bool busy = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    var next = const MetaConfig();
    if (raw != null) {
      try {
        next = MetaConfig.fromPublicJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    final secret = await _store.readMetaAppSecret() ?? '';
    final token = await _store.readMetaUserToken() ?? '';
    state = next.copyWith(appSecret: secret, userAccessToken: token);
  }

  Future<void> save(MetaConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(cfg.toPublicJson()));
    await _store.saveMetaAppSecret(cfg.appSecret);
    await _store.saveMetaUserToken(cfg.userAccessToken);
    state = cfg;
    lastActionMessage = 'Configuración Meta guardada';
  }

  Future<String> validateToken() async {
    if (!state.hasToken) return 'Falta el token de acceso';
    try {
      final me = await _service.validateMe(state);
      final name = me['name'] ?? me['id'];
      var msg = 'Token válido · usuario Graph: $name';
      try {
        if (state.hasAppId && state.appSecret.isNotEmpty) {
          final debug = await _service.debugToken(state);
          final data = debug['data'] as Map<String, dynamic>?;
          final valid = data?['is_valid'] == true;
          final scopes = data?['scopes'];
          msg += valid
              ? '\ndebug_token: válido · scopes: $scopes'
              : '\ndebug_token: inválido o expirado';
        }
      } catch (e) {
        msg += '\ndebug_token omitido: $e';
      }
      state = state.copyWith(
        connectionOk: true,
        lastValidationMessage: msg,
        lastValidatedAt: DateTime.now(),
      );
      await _persistPublic();
      lastActionMessage = msg;
      return msg;
    } catch (e) {
      final msg = 'Validación falló: $e';
      state = state.copyWith(
        connectionOk: false,
        lastValidationMessage: msg,
        lastValidatedAt: DateTime.now(),
      );
      await _persistPublic();
      lastActionMessage = msg;
      return msg;
    }
  }

  Future<List<MetaPageInfo>> listPages() async {
    pages = await _service.listPages(state);
    lastActionMessage = pages.isEmpty
        ? 'No se encontraron páginas (revisa permisos pages_show_list / pages_manage_posts)'
        : '${pages.length} página(s) encontradas';
    return pages;
  }

  Future<MetaPublishResult> publishPagePost(String message) async {
    final result = await _service.publishPagePost(
      cfg: state,
      message: message,
    );
    lastActionMessage = result.message;
    return result;
  }

  Future<void> _persistPublic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toPublicJson()));
  }
}

final metaProvider = StateNotifierProvider<MetaNotifier, MetaConfig>((ref) {
  return MetaNotifier(
    ref.watch(secureStoreProvider),
    ref.watch(metaGraphServiceProvider),
  );
});
