import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/bg_remover.dart';

/// Proveedor pluggable: POST multipart a un endpoint HTTP configurable.
/// Compatible con APIs estilo OpenAI-compatible o proxies propios.
class GenericHttpBgRemover implements BgRemover {
  GenericHttpBgRemover({
    required this.endpoint,
    required this.apiKey,
    this.model = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String endpoint;
  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  String get id => 'generic_http';

  @override
  String get label => 'HTTP genérico';

  @override
  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    if (endpoint.trim().isEmpty) {
      throw StateError(
        'Configura el endpoint HTTP genérico en Ajustes IA.',
      );
    }
    final uri = Uri.parse(endpoint.trim());
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageBytes,
          filename: 'mochila.jpg',
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'HTTP genérico ${response.statusCode}: ${response.body}',
      );
    }
    return response.bodyBytes;
  }
}
