import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inicializa sqflite FFI en escritorio (Linux/Windows/macOS).
void initDesktopSqflite() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
