class PhotoGroup {
  const PhotoGroup({
    required this.id,
    required this.name,
    this.photoPaths = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final List<String> photoPaths;
  final DateTime? createdAt;

  PhotoGroup copyWith({
    String? id,
    String? name,
    List<String>? photoPaths,
    DateTime? createdAt,
  }) {
    return PhotoGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoPaths': photoPaths,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PhotoGroup.fromJson(Map<String, dynamic> json) => PhotoGroup(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? const [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
