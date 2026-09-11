import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/models/meta_config.dart';

/// Cliente Graph API (sin scraping). Marketplace de ítems no está
/// disponible de forma pública; se usa feed de Página cuando aplica.
class MetaGraphService {
  MetaGraphService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(MetaConfig cfg, String path, [Map<String, String>? query]) {
    final version = cfg.graphApiVersion.startsWith('v')
        ? cfg.graphApiVersion
        : 'v${cfg.graphApiVersion}';
    final q = <String, String>{
      'access_token': cfg.userAccessToken,
      ...?query,
    };
    return Uri.https('graph.facebook.com', '/$version/$path', q);
  }

  Future<Map<String, dynamic>> validateMe(MetaConfig cfg) async {
    final res = await _client.get(_uri(cfg, 'me', {'fields': 'id,name'}));
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw MetaGraphException(_errorMessage(body), res.statusCode);
    }
    return body;
  }

  /// Requiere app_id + app_secret + token de usuario.
  Future<Map<String, dynamic>> debugToken(MetaConfig cfg) async {
    if (!cfg.hasAppId || cfg.appSecret.isEmpty) {
      throw MetaGraphException(
        'App ID y App Secret necesarios para debug_token',
        400,
      );
    }
    final appToken = '${cfg.appId}|${cfg.appSecret}';
    final uri = Uri.https(
      'graph.facebook.com',
      '/${cfg.graphApiVersion}/debug_token',
      {
        'input_token': cfg.userAccessToken,
        'access_token': appToken,
      },
    );
    final res = await _client.get(uri);
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw MetaGraphException(_errorMessage(body), res.statusCode);
    }
    return body;
  }

  Future<List<MetaPageInfo>> listPages(MetaConfig cfg) async {
    final res = await _client.get(
      _uri(cfg, 'me/accounts', {
        'fields': 'id,name,access_token,category',
      }),
    );
    final body = _decode(res);
    if (res.statusCode >= 400) {
      throw MetaGraphException(_errorMessage(body), res.statusCode);
    }
    final data = body['data'] as List? ?? const [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return MetaPageInfo(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        accessToken: m['access_token']?.toString(),
        category: m['category']?.toString(),
      );
    }).where((p) => p.id.isNotEmpty).toList();
  }

  /// Publica en el feed de la Página. No crea ítems de Marketplace
  /// (API pública no lo permite de forma general).
  Future<MetaPublishResult> publishPagePost({
    required MetaConfig cfg,
    required String message,
    String? link,
    String? pageAccessToken,
  }) async {
    final pageId = cfg.pageId.trim();
    if (pageId.isEmpty) {
      return const MetaPublishResult(
        ok: false,
        message: 'Configura un Page ID primero',
      );
    }
    final token = (pageAccessToken != null && pageAccessToken.isNotEmpty)
        ? pageAccessToken
        : cfg.userAccessToken;
    final version = cfg.graphApiVersion.startsWith('v')
        ? cfg.graphApiVersion
        : 'v${cfg.graphApiVersion}';
    final uri = Uri.https(
      'graph.facebook.com',
      '/$version/$pageId/feed',
    );
    final res = await _client.post(
      uri,
      body: {
        'message': message,
        if (link != null && link.isNotEmpty) 'link': link,
        'access_token': token,
      },
    );
    final body = _decode(res);
    if (res.statusCode >= 400) {
      return MetaPublishResult(
        ok: false,
        message: _errorMessage(body),
      );
    }
    final id = body['id']?.toString();
    return MetaPublishResult(
      ok: true,
      message: 'Publicado en feed de Página',
      postId: id,
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'raw': res.body};
    }
  }

  String _errorMessage(Map<String, dynamic> body) {
    final err = body['error'];
    if (err is Map) {
      return '${err['message'] ?? err} '
          '(code: ${err['code']}, type: ${err['type']})';
    }
    return body['raw']?.toString() ?? body.toString();
  }
}

class MetaGraphException implements Exception {
  MetaGraphException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => 'MetaGraphException($statusCode): $message';
}
