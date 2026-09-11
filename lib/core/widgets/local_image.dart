import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Muestra una imagen local; en web muestra placeholder (path no es File).
class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.image, size: 48)),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.broken_image, size: 48)),
      ),
    );
  }
}
