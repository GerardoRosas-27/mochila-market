class ListingDraft {
  const ListingDraft({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    this.imagePath,
    this.marketplace = 'demo',
    this.status = ListingStatus.borrador,
    this.createdAt,
  });

  final String id;
  final String title;
  final double price;
  final String description;
  final String? imagePath;
  final String marketplace;
  final ListingStatus status;
  final DateTime? createdAt;

  ListingDraft copyWith({
    String? id,
    String? title,
    double? price,
    String? description,
    String? imagePath,
    String? marketplace,
    ListingStatus? status,
    DateTime? createdAt,
  }) {
    return ListingDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
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
        'marketplace': marketplace,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ListingDraft.fromJson(Map<String, dynamic> json) => ListingDraft(
        id: json['id'] as String,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        imagePath: json['imagePath'] as String?,
        marketplace: json['marketplace'] as String? ?? 'demo',
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
