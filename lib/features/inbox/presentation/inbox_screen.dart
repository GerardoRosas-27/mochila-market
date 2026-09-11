import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inbox_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _loadingId;

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox · respuestas IA')),
      body: messages.isEmpty
          ? const Center(child: Text('Sin mensajes'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final m = messages[index];
                final loading = _loadingId == m.id;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.buyerName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (!m.isRead)
                              const Chip(
                                label: Text('Nuevo'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        Text(
                          m.productName,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(m.body),
                        if (m.aiReply != null) ...[
                          const Divider(height: 24),
                          Text(
                            'Respuesta IA',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(m.aiReply!),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: loading
                                ? null
                                : () async {
                                    setState(() => _loadingId = m.id);
                                    try {
                                      await ref
                                          .read(inboxProvider.notifier)
                                          .generateAiReply(m.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _loadingId = null);
                                      }
                                    }
                                  },
                            icon: loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              m.aiReply == null
                                  ? 'Generar respuesta IA'
                                  : 'Regenerar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
