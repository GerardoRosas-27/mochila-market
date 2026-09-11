/// Inventario rico de productos (mochilas). Migra/reemplaza el catálogo fino.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.sku = '',
    this.stock = 1,
    this.available = true,
    this.colors = const [],
    this.sizes = const [],
    this.material = '',
    this.brand = '',
    this.condition = ProductCondition.nuevo,
    this.tags = const [],
    this.photoPaths = const [],
    this.locationOverride = '',
    this.category = 'mochila',
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String sku;
  final int stock;
  final bool available;
  final List<String> colors;
  final List<String> sizes;
  final String material;
  final String brand;
  final ProductCondition condition;
  final List<String> tags;
  final List<String> photoPaths;
  final String locationOverride;
  final String category;

  String? get primaryPhoto =>
      photoPaths.isNotEmpty ? photoPaths.first : null;

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? sku,
    int? stock,
    bool? available,
    List<String>? colors,
    List<String>? sizes,
    String? material,
    String? brand,
    ProductCondition? condition,
    List<String>? tags,
    List<String>? photoPaths,
    String? locationOverride,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
      available: available ?? this.available,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      material: material ?? this.material,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      tags: tags ?? this.tags,
      photoPaths: photoPaths ?? this.photoPaths,
      locationOverride: locationOverride ?? this.locationOverride,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'description': description,
        'sku': sku,
        'stock': stock,
        'available': available,
        'colors': colors,
        'sizes': sizes,
        'material': material,
        'brand': brand,
        'condition': condition.name,
        'tags': tags,
        'photoPaths': photoPaths,
        'locationOverride': locationOverride,
        'category': category,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        stock: json['stock'] as int? ?? 1,
        available: json['available'] as bool? ?? true,
        colors: (json['colors'] as List?)?.cast<String>() ?? const [],
        sizes: (json['sizes'] as List?)?.cast<String>() ?? const [],
        material: json['material'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        condition: ProductCondition.values.firstWhere(
          (e) => e.name == json['condition'],
          orElse: () => ProductCondition.nuevo,
        ),
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
        photoPaths: (json['photoPaths'] as List?)?.cast<String>() ??
            (json['imagePath'] != null
                ? [json['imagePath'] as String]
                : const []),
        locationOverride: json['locationOverride'] as String? ?? '',
        category: json['category'] as String? ?? 'mochila',
      );

  /// Compatibilidad con modelo Backpack antiguo.
  factory Product.fromBackpackJson(Map<String, dynamic> json) =>
      Product.fromJson({
        ...json,
        if (json['imagePath'] != null && json['photoPaths'] == null)
          'photoPaths': [json['imagePath']],
      });
}

enum ProductCondition { nuevo, comoNuevo, buenEstado, aceptable }

extension ProductConditionLabel on ProductCondition {
  String get labelEs => switch (this) {
        ProductCondition.nuevo => 'Nuevo',
        ProductCondition.comoNuevo => 'Como nuevo',
        ProductCondition.buenEstado => 'Buen estado',
        ProductCondition.aceptable => 'Aceptable',
      };
}
