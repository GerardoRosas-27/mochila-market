import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../bg_removal/data/bg_removal_service.dart';

class PhotoSession {
  const PhotoSession({
    this.originalPath,
    this.processedPath,
    this.isProcessing = false,
    this.error,
  });

  final String? originalPath;
  final String? processedPath;
  final bool isProcessing;
  final String? error;

  PhotoSession copyWith({
    String? originalPath,
    String? processedPath,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    bool clearProcessed = false,
  }) {
    return PhotoSession(
      originalPath: originalPath ?? this.originalPath,
      processedPath:
          clearProcessed ? null : (processedPath ?? this.processedPath),
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CameraNotifier extends StateNotifier<PhotoSession> {
  CameraNotifier(this._bg) : super(const PhotoSession());

  final BgRemovalService _bg;
  final _picker = ImagePicker();
  final _uuid = const Uuid();
  XFile? _lastPicked;

  Future<void> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return;
      _lastPicked = file;
      state = PhotoSession(originalPath: file.path);
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo abrir la galería: $e',
      );
    }
  }

  Future<void> pickFromCamera() async {
    if (kIsWeb) {
      state = state.copyWith(
        error:
            'La cámara no está disponible en el navegador. '
            'Usa «Galería» para subir una foto.',
      );
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      _lastPicked = file;
      state = PhotoSession(originalPath: file.path);
    } catch (e) {
      state = state.copyWith(
        error:
            'No se pudo abrir la cámara. Prueba con «Galería». '
            '($e)',
      );
    }
  }

  Future<void> removeBackground() async {
    if (state.originalPath == null && _lastPicked == null) return;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final Uint8List bytes;
      if (_lastPicked != null) {
        bytes = await _lastPicked!.readAsBytes();
      } else {
        bytes = await XFile(state.originalPath!).readAsBytes();
      }
      final out = await _bg.remove(bytes);
      if (kIsWeb) {
        // Sin filesystem en web: marcamos procesado; LocalImage usa placeholder.
        state = state.copyWith(
          processedPath: state.originalPath,
          isProcessing: false,
        );
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final outPath = p.join(dir.path, 'bg_${_uuid.v4()}.png');
      await XFile.fromData(out, name: p.basename(outPath)).saveTo(outPath);
      state = state.copyWith(
        processedPath: outPath,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    _lastPicked = null;
    state = const PhotoSession();
  }
}

final cameraProvider =
    StateNotifierProvider<CameraNotifier, PhotoSession>((ref) {
  return CameraNotifier(ref.watch(bgRemovalServiceProvider));
});
