class ListingDraft {
  const ListingDraft({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    this.imagePath,
    this.imagePaths = const [],
    this.productId,
    this.photoGroupId,
    this.marketplace = 'local',
    this.status = ListingStatus.borrador,
    this.createdAt,
  });

  final String id;
  final String title;
  final double price;
  final String description;
  final String? imagePath;
  final List<String> imagePaths;
  final String? productId;
  final String? photoGroupId;
  final String marketplace;
  final ListingStatus status;
  final DateTime? createdAt;

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
    String? photoGroupId,
    String? marketplace,
    ListingStatus? status,
    DateTime? createdAt,
    bool clearPhotoGroupId = false,
  }) {
    return ListingDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      productId: productId ?? this.productId,
      photoGroupId:
          clearPhotoGroupId ? null : (photoGroupId ?? this.photoGroupId),
      marketplace: marketplace ?? this.marketplace,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
        'photoGroupId': photoGroupId,
        'marketplace': marketplace,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ListingDraft.fromJson(Map<String, dynamic> json) => ListingDraft(
        id: json['id'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? const [],
        productId: json['productId'] as String?,
        photoGroupId: json['photoGroupId'] as String?,
        marketplace: json['marketplace'] as String? ?? 'local',
        status: ListingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ListingStatus.borrador,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

enum ListingStatus { borrador, listo, publicado }

extension ListingStatusLabel on ListingStatus {
  String get labelEs => switch (this) {
        ListingStatus.borrador => 'Borrador',
        ListingStatus.listo => 'Listo para pegar',
        ListingStatus.publicado => 'Marcado publicado (local)',
      };
}
