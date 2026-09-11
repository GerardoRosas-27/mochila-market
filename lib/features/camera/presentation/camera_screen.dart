import 'package:flutter/material.dart';
import '../../../core/widgets/local_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../marketplace/presentation/marketplace_provider.dart';
import 'camera_provider.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(cameraProvider);
    final notifier = ref.read(cameraProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos de mochilas'),
        actions: [
          IconButton(
            tooltip: 'Ajustes IA / fondo',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/ajustes-ia'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Captura o elige una foto, quita el fondo y envíala a un borrador '
            'de Marketplace.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: session.isProcessing
                      ? null
                      : () => notifier.pickFromCamera(),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: session.isProcessing
                      ? null
                      : () => notifier.pickFromGallery(),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (session.originalPath != null) ...[
            _ImageCard(
              title: 'Original',
              path: session.originalPath!,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: session.isProcessing
                  ? null
                  : () => notifier.removeBackground(),
              icon: session.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                session.isProcessing
                    ? 'Quitando fondo…'
                    : 'Quitar fondo',
              ),
            ),
          ],
          if (session.processedPath != null) ...[
            const SizedBox(height: 12),
            _ImageCard(
              title: 'Sin fondo',
              path: session.processedPath!,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final path =
                    session.processedPath ?? session.originalPath;
                ref.read(marketplaceProvider.notifier).create(
                      title: 'Mochila (nueva foto)',
                      price: 0,
                      description:
                          'Borrador creado desde foto. Completa título y precio.',
                      imagePath: path,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Borrador añadido en Marketplace'),
                  ),
                );
                context.go('/marketplace');
              },
              icon: const Icon(Icons.storefront),
              label: const Text('Crear borrador Marketplace'),
            ),
          ],
          if (session.error != null) ...[
            const SizedBox(height: 12),
            Text(
              session.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (session.originalPath != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => notifier.clear(),
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.title, required this.path});

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: LocalImage(path: path, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
