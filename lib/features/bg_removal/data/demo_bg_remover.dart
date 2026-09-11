import 'dart:typed_data';

import '../domain/bg_remover.dart';

/// Remoción de fondo simulada (devuelve los mismos bytes con un marcador).
/// En demo no altera píxeles reales; sirve para flujo UI sin API.
class DemoBgRemover implements BgRemover {
  @override
  String get id => 'demo';

  @override
  String get label => 'Demo (sin API)';

  @override
  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Simula procesamiento; en producción un modelo local alteraría píxeles.
    return Uint8List.fromList(imageBytes);
  }
}
