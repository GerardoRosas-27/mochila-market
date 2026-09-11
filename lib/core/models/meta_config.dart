class MetaConfig {
  const MetaConfig({
    this.appId = '',
    this.appSecret = '',
    this.userAccessToken = '',
    this.pageId = '',
    this.graphApiVersion = 'v21.0',
    this.lastValidationMessage = '',
    this.lastValidatedAt,
    this.connectionOk = false,
  });

  final String appId;
  final String appSecret;
  final String userAccessToken;
  final String pageId;
  final String graphApiVersion;
  final String lastValidationMessage;
  final DateTime? lastValidatedAt;
  final bool connectionOk;

  bool get hasToken => userAccessToken.trim().isNotEmpty;
  bool get hasAppId => appId.trim().isNotEmpty;

  MetaConfig copyWith({
    String? appId,
    String? appSecret,
    String? userAccessToken,
    String? pageId,
    String? graphApiVersion,
    String? lastValidationMessage,
    DateTime? lastValidatedAt,
    bool? connectionOk,
  }) {
    return MetaConfig(
      appId: appId ?? this.appId,
      appSecret: appSecret ?? this.appSecret,
      userAccessToken: userAccessToken ?? this.userAccessToken,
      pageId: pageId ?? this.pageId,
      graphApiVersion: graphApiVersion ?? this.graphApiVersion,
      lastValidationMessage:
          lastValidationMessage ?? this.lastValidationMessage,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
      connectionOk: connectionOk ?? this.connectionOk,
    );
  }

  /// Solo campos no secretos.
  Map<String, dynamic> toPublicJson() => {
        'appId': appId,
        'pageId': pageId,
        'graphApiVersion': graphApiVersion,
        'lastValidationMessage': lastValidationMessage,
        'lastValidatedAt': lastValidatedAt?.toIso8601String(),
        'connectionOk': connectionOk,
      };

  factory MetaConfig.fromPublicJson(Map<String, dynamic> json) => MetaConfig(
        appId: json['appId'] as String? ?? '',
        pageId: json['pageId'] as String? ?? '',
        graphApiVersion: json['graphApiVersion'] as String? ?? 'v21.0',
        lastValidationMessage: json['lastValidationMessage'] as String? ?? '',
        lastValidatedAt: json['lastValidatedAt'] != null
            ? DateTime.tryParse(json['lastValidatedAt'] as String)
            : null,
        connectionOk: json['connectionOk'] as bool? ?? false,
      );
}

class MetaPageInfo {
  const MetaPageInfo({
    required this.id,
    required this.name,
    this.accessToken,
    this.category,
  });

  final String id;
  final String name;
  final String? accessToken;
  final String? category;
}

class MetaPublishResult {
  const MetaPublishResult({
    required this.ok,
    required this.message,
    this.postId,
  });

  final bool ok;
  final String message;
  final String? postId;
}
