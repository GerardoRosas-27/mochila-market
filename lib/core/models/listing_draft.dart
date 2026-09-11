class ListingDraft {
  const ListingDraft({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    this.imagePath,
    this.imagePaths = const [],
    this.productId,
    this.marketplace = 'demo',
    this.status = ListingStatus.borrador,
    this.createdAt,
    this.metaPostId,
    this.publishChannel = PublishChannel.borradorLocal,
  });

  final String id;
  final String title;
  final double price;
  final String description;
  final String? imagePath;
  final List<String> imagePaths;
  final String? productId;
  final String marketplace;
  final ListingStatus status;
  final DateTime? createdAt;
  final String? metaPostId;
  final PublishChannel publishChannel;

  List<String> get allImages {
    if (imagePaths.isNotEmpty) return imagePaths;
    if (imagePath != null && imagePath!.isNotEmpty) return [imagePath!];
    return const [];
  }

  ListingDraft copyWith({
    String? id,
    String? title,
    double? price,
    String? description,
    String? imagePath,
    List<String>? imagePaths,
    String? productId,
    String? marketplace,
    ListingStatus? status,
    DateTime? createdAt,
    String? metaPostId,
    PublishChannel? publishChannel,
  }) {
    return ListingDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      productId: productId ?? this.productId,
      marketplace: marketplace ?? this.marketplace,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metaPostId: metaPostId ?? this.metaPostId,
      publishChannel: publishChannel ?? this.publishChannel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'imagePath': imagePath,
        'imagePaths': imagePaths,
        'productId': productId,
        'marketplace': marketplace,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'metaPostId': metaPostId,
        'publishChannel': publishChannel.name,
      };

  factory ListingDraft.fromJson(Map<String, dynamic> json) => ListingDraft(
        id: json['id'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        imagePath: json['imagePath'] as String?,
        imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? const [],
        productId: json['productId'] as String?,
        marketplace: json['marketplace'] as String? ?? 'demo',
        status: ListingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ListingStatus.borrador,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        metaPostId: json['metaPostId'] as String?,
        publishChannel: PublishChannel.values.firstWhere(
          (e) => e.name == json['publishChannel'],
          orElse: () => PublishChannel.borradorLocal,
        ),
      );
}

enum ListingStatus { borrador, listo, publicado }

enum PublishChannel {
  borradorLocal,
  pageFeed,
  /// Marketplace de ítems no está expuesto de forma pública en Graph API.
  marketplaceNoDisponible,
}

extension PublishChannelLabel on PublishChannel {
  String get labelEs => switch (this) {
        PublishChannel.borradorLocal => 'Borrador local',
        PublishChannel.pageFeed => 'Publicación en Página (Graph)',
        PublishChannel.marketplaceNoDisponible =>
          'Marketplace (no disponible vía API pública)',
      };
}
