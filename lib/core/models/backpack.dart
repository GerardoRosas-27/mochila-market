class Backpack {
  const Backpack({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.description,
    this.imagePath,
    this.category = 'mochila',
    this.stock = 1,
  });

  final String id;
  final String name;
  final String brand;
  final double price;
  final String description;
  final String? imagePath;
  final String category;
  final int stock;

  Backpack copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? description,
    String? imagePath,
    String? category,
    int? stock,
  }) {
    return Backpack(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'price': price,
        'description': description,
        'imagePath': imagePath,
        'category': category,
        'stock': stock,
      };

  factory Backpack.fromJson(Map<String, dynamic> json) => Backpack(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        imagePath: json['imagePath'] as String?,
        category: json['category'] as String? ?? 'mochila',
        stock: json['stock'] as int? ?? 1,
      );
}
