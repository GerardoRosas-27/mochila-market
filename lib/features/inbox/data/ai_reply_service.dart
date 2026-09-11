import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/ai_settings.dart';
import '../../../core/storage/secure_store.dart';
import '../../ai_settings/presentation/ai_settings_provider.dart';

final aiReplyServiceProvider = Provider<AiReplyService>((ref) {
  return AiReplyService(
    settings: ref.watch(aiSettingsProvider),
    store: ref.watch(secureStoreProvider),
  );
});

class AiReplyService {
  AiReplyService({required this.settings, required this.store});

  final AiSettings settings;
  final SecureStore store;

  /// Genera una respuesta de inbox. Usa API multimodal si hay clave; si no, demo.
  Future<String> generateReply({
    required String buyerName,
    required String productName,
    required String message,
    String companyContext = '',
  }) async {
    final apiKey =
        await store.readMultimodalApiKey() ?? settings.multimodalApiKey;
    final base = settings.multimodalApiBaseUrl.trim();

    if (apiKey.isNotEmpty && base.isNotEmpty) {
      return _callMultimodalApi(
        baseUrl: base,
        apiKey: apiKey,
        model: settings.multimodalModel,
        buyerName: buyerName,
        productName: productName,
        message: message,
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _demoReply(
      buyerName: buyerName,
      productName: productName,
      message: message,
      companyContext: companyContext,
    );
  }

  String _demoReply({
    required String buyerName,
    required String productName,
    required String message,
    String companyContext = '',
  }) {
    final lower = message.toLowerCase();
    final locHint = companyContext.isEmpty
        ? ''
        : ' (tienda: $companyContext)';
    if (lower.contains('envío') || lower.contains('envio') || lower.contains('horario') || lower.contains('dirección') || lower.contains('direccion')) {
      if (companyContext.isNotEmpty && (lower.contains('horario') || lower.contains('dirección') || lower.contains('direccion') || lower.contains('ubicación') || lower.contains('ubicacion'))) {
        return '¡Hola $buyerName! Datos de la tienda$locHint. '
            '¿Te ayudo con $productName o con el envío?';
      }
      return '¡Hola $buyerName! El envío de $productName sale en 24–48 h '
          'hábiles a toda la República$locHint. ¿Me compartes tu CP para cotizar?';
    }
    if (lower.contains('precio') || lower.contains('descuento')) {
      return 'Hola $buyerName, el precio de $productName es el publicado. '
          'Puedo ofrecerte un pequeño descuento si llevas 2 o más. ¡Avísame!';
    }
    if (lower.contains('medida') || lower.contains('tamaño')) {
      return 'Claro $buyerName: $productName incluye ficha de medidas en la '
          'publicación. Si necesitas algo específico, dime y te confirmo.';
    }
    return '¡Hola $buyerName! Gracias por tu interés en $productName. '
        'Con gusto te ayudo: ¿buscas info de stock, envío o personalización?';
  }

  Future<String> _callMultimodalApi({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String buyerName,
    required String productName,
    required String message,
  }) async {
    final uri = Uri.parse(
      baseUrl.endsWith('/')
          ? '${baseUrl}chat/completions'
          : '$baseUrl/chat/completions',
    );
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un vendedor mexicano de mochilas en Marketplace. '
              'Responde en español, breve y amable.',
        },
        {
          'role': 'user',
          'content':
              'Comprador: $buyerName\nProducto: $productName\nMensaje: $message',
        },
      ],
      'temperature': 0.6,
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('API multimodal ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw StateError('Respuesta vacía de la API multimodal');
    }
    final msg = choices.first['message'] as Map<String, dynamic>;
    return msg['content'] as String? ?? _demoReply(
      buyerName: buyerName,
      productName: productName,
      message: message,
    );
  }
}
