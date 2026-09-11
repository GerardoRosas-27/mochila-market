import 'dart:typed_data';

/// Contrato pluggable para quitar el fondo de una imagen.
abstract class BgRemover {
  String get id;
  String get label;
  Future<Uint8List> removeBackground(Uint8List imageBytes);
}
