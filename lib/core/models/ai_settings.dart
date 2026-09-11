class AiSettings {
  const AiSettings({
    this.imageApiBaseUrl = '',
    this.imageApiKey = '',
    this.imageModel = 'gpt-image-1',
    this.multimodalApiBaseUrl = '',
    this.multimodalApiKey = '',
    this.multimodalModel = 'gpt-4o-mini',
    this.removeBgApiKey = '',
    this.bgProvider = BgProvider.demo,
  });

  final String imageApiBaseUrl;
  final String imageApiKey;
  final String imageModel;
  final String multimodalApiBaseUrl;
  final String multimodalApiKey;
  final String multimodalModel;
  final String removeBgApiKey;
  final BgProvider bgProvider;

  AiSettings copyWith({
    String? imageApiBaseUrl,
    String? imageApiKey,
    String? imageModel,
    String? multimodalApiBaseUrl,
    String? multimodalApiKey,
    String? multimodalModel,
    String? removeBgApiKey,
    BgProvider? bgProvider,
  }) {
    return AiSettings(
      imageApiBaseUrl: imageApiBaseUrl ?? this.imageApiBaseUrl,
      imageApiKey: imageApiKey ?? this.imageApiKey,
      imageModel: imageModel ?? this.imageModel,
      multimodalApiBaseUrl: multimodalApiBaseUrl ?? this.multimodalApiBaseUrl,
      multimodalApiKey: multimodalApiKey ?? this.multimodalApiKey,
      multimodalModel: multimodalModel ?? this.multimodalModel,
      removeBgApiKey: removeBgApiKey ?? this.removeBgApiKey,
      bgProvider: bgProvider ?? this.bgProvider,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageApiBaseUrl': imageApiBaseUrl,
        'imageModel': imageModel,
        'multimodalApiBaseUrl': multimodalApiBaseUrl,
        'multimodalModel': multimodalModel,
        'bgProvider': bgProvider.name,
      };

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
        imageApiBaseUrl: json['imageApiBaseUrl'] as String? ?? '',
        imageModel: json['imageModel'] as String? ?? 'gpt-image-1',
        multimodalApiBaseUrl: json['multimodalApiBaseUrl'] as String? ?? '',
        multimodalModel: json['multimodalModel'] as String? ?? 'gpt-4o-mini',
        bgProvider: BgProvider.values.firstWhere(
          (e) => e.name == json['bgProvider'],
          orElse: () => BgProvider.demo,
        ),
      );
}

enum BgProvider { demo, removeBg }
