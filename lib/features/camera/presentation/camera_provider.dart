import 'dart:io';
import 'dart:typed_data';

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

  Future<void> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;
    state = PhotoSession(originalPath: file.path);
  }

  Future<void> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) return;
    state = PhotoSession(originalPath: file.path);
  }

  Future<void> removeBackground() async {
    final path = state.originalPath;
    if (path == null) return;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final bytes = await File(path).readAsBytes();
      final out = await _bg.remove(Uint8List.fromList(bytes));
      final dir = await getApplicationDocumentsDirectory();
      final outPath = p.join(dir.path, 'bg_${_uuid.v4()}.png');
      await File(outPath).writeAsBytes(out);
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

  void clear() => state = const PhotoSession();
}

final cameraProvider =
    StateNotifierProvider<CameraNotifier, PhotoSession>((ref) {
  return CameraNotifier(ref.watch(bgRemovalServiceProvider));
});
