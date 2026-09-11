import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/bg_remover.dart';

/// Cliente HTTP hacia remove.bg (https://www.remove.bg/api).
class RemoveBgHttpRemover implements BgRemover {
  RemoveBgHttpRemover({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _endpoint = 'https://api.remove.bg/v1.0/removebg';

  @override
  String get id => 'remove.bg';

  @override
  String get label => 'remove.bg (HTTP)';

  @override
  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('Falta la API key de remove.bg en Ajustes IA.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..headers['X-Api-Key'] = apiKey
      ..fields['size'] = 'auto'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageBytes,
          filename: 'mochila.jpg',
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw StateError(
        'remove.bg error ${response.statusCode}: ${response.body}',
      );
    }
    return response.bodyBytes;
  }
}
