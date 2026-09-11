import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/inbox_message.dart';
import '../data/ai_reply_service.dart';

class InboxNotifier extends StateNotifier<List<InboxMessage>> {
  InboxNotifier(this._ai) : super(_seed());

  final AiReplyService _ai;
  final _uuid = const Uuid();

  static List<InboxMessage> _seed() {
    final now = DateTime.now();
    return [
      InboxMessage(
        id: const Uuid().v4(),
        buyerName: 'Ana López',
        productName: 'TrailPro 40L',
        body: '¿Hacen envío a Guadalajara y cuánto tarda?',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      InboxMessage(
        id: const Uuid().v4(),
        buyerName: 'Carlos Ruiz',
        productName: 'Urban Slim 20L',
        body: '¿Tienen descuento si compro dos?',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      InboxMessage(
        id: const Uuid().v4(),
        buyerName: 'María Soto',
        productName: 'Kids Dino 12L',
        body: '¿Cuáles son las medidas exactas?',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> generateAiReply(String id) async {
    final msg = state.firstWhere((m) => m.id == id);
    final reply = await _ai.generateReply(
      buyerName: msg.buyerName,
      productName: msg.productName,
      message: msg.body,
    );
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(aiReply: reply, isRead: true) else m,
    ];
  }

  void markRead(String id) {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(isRead: true) else m,
    ];
  }

  void addManual({
    required String buyerName,
    required String productName,
    required String body,
  }) {
    state = [
      InboxMessage(
        id: _uuid.v4(),
        buyerName: buyerName,
        productName: productName,
        body: body,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
  }
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, List<InboxMessage>>((ref) {
  return InboxNotifier(ref.watch(aiReplyServiceProvider));
});
