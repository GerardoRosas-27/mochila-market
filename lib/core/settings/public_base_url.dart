import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// URL pública (p. ej. Railway) para enlaces de oferta `/p/:slug`
/// y producto `/producto/:id`.
class PublicBaseUrlNotifier extends StateNotifier<String> {
  PublicBaseUrlNotifier() : super('') {
    _load();
  }

  static const prefsKey = 'public_base_url_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(prefsKey) ?? '';
  }

  Future<void> setUrl(String raw) async {
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, url);
    state = url;
  }

  String shareUrlForPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    if (state.isEmpty) return p;
    return '$state$p';
  }

  String shareUrlForSlug(String slug) => shareUrlForPath('/p/$slug');

  String shareUrlForProduct(String productId) =>
      shareUrlForPath('/producto/$productId');
}

final publicBaseUrlProvider =
    StateNotifierProvider<PublicBaseUrlNotifier, String>((ref) {
  return PublicBaseUrlNotifier();
});
