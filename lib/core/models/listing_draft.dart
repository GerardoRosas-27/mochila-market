/// Publicación = grupo de ofertas (uno o más productos del inventario).
/// No es 1:1 con un producto. Aparece en `/p/:slug` para compartir en Marketplace.
/// «Exportar como borrador» copia texto de plantilla al portapapeles (no es estado).
class ListingDraft {
  const ListingDraft({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    this.imagePath,
    this.imagePaths = const [],
    this.productId,
    this.productIds = const [],
    this.photoGroupId,
    this.marketplace = 'local',
    this.status = ListingStatus.activa,
    this.createdAt,
    this.slug = '',
  });

  final String id;
  final String title;
  /// Precio de referencia (p. ej. mínimo del grupo o el fijado al exportar).
  final double price;
  final String description;
  final String? imagePath;
  final List<String> imagePaths;
  /// Compat: producto único legacy.
  final String? productId;
  /// Productos del inventario incluidos en esta oferta/grupo.
  final List<String> productIds;
  final String? photoGroupId;
  final String marketplace;
  final ListingStatus status;
  final DateTime? createdAt;
  /// Slug estable para URLs públicas `/p/:slug`.
  final String slug;

  /// IDs de productos del grupo (productIds + productId legacy).
  List<String> get allProductIds {
    final out = <String>[];
    final seen = <String>{};
    for (final id in [...productIds, if (productId != null) productId!]) {
      if (id.isNotEmpty && seen.add(id)) out.add(id);
    }
    return out;
  }

  List<String> get allImages {
    if (imagePaths.isNotEmpty) return imagePaths;
    if (imagePath != null && imagePath!.isNotEmpty) return [imagePath!];
    return const [];
  }

  bool get isActive =>
      status == ListingStatus.activa || status == ListingStatus.listo;

  ListingDraft copyWith({
    String? id,
    String? title,
    double? price,
    String? description,
    String? imagePath,
    List<String>? imagePaths,
    String? productId,
    List<String>? productIds,
    String? photoGroupId,
    String? marketplace,
    ListingStatus? status,
    DateTime? createdAt,
    String? slug,
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
      productIds: productIds ?? this.productIds,
      photoGroupId:
          clearPhotoGroupId ? null : (photoGroupId ?? this.photoGroupId),
      marketplace: marketplace ?? this.marketplace,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      slug: slug ?? this.slug,
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
        'productIds': productIds,
        'photoGroupId': photoGroupId,
        'marketplace': marketplace,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'slug': slug,
      };

  factory ListingDraft.fromJson(Map<String, dynamic> json) {
    final legacyId = json['productId'] as String?;
    final ids = (json['productIds'] as List?)?.cast<String>() ?? const [];
    return ListingDraft(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? const [],
      productId: legacyId,
      productIds: ids,
      photoGroupId: json['photoGroupId'] as String?,
      marketplace: json['marketplace'] as String? ?? 'local',
      status: _parseStatus(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      slug: json['slug'] as String? ?? '',
    );
  }

  static ListingStatus _parseStatus(String? name) {
    if (name == null) return ListingStatus.activa;
    if (name == 'borrador' || name == 'publicado') {
      return ListingStatus.activa;
    }
    return ListingStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ListingStatus.activa,
    );
  }
}

enum ListingStatus { activa, listo, archivada }

extension ListingStatusLabel on ListingStatus {
  String get labelEs => switch (this) {
        ListingStatus.activa => 'Activa',
        ListingStatus.listo => 'Lista para Marketplace',
        ListingStatus.archivada => 'Archivada',
      };
}
