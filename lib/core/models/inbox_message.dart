class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.buyerName,
    required this.productName,
    required this.body,
    this.aiReply,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String buyerName;
  final String productName;
  final String body;
  final String? aiReply;
  final DateTime? createdAt;
  final bool isRead;

  InboxMessage copyWith({
    String? id,
    String? buyerName,
    String? productName,
    String? body,
    String? aiReply,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return InboxMessage(
      id: id ?? this.id,
      buyerName: buyerName ?? this.buyerName,
      productName: productName ?? this.productName,
      body: body ?? this.body,
      aiReply: aiReply ?? this.aiReply,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
