class MarketplaceTemplate {
  const MarketplaceTemplate({
    this.titleTemplate = defaultTitle,
    this.bodyTemplate = defaultBody,
  });

  final String titleTemplate;
  final String bodyTemplate;

  static const defaultTitle = '{{nombre}} — {{marca}} · \${{precio}}';

  static const defaultBody = '''{{descripcion}}

Marca: {{marca}}
SKU: {{sku}}
Colores: {{colores}}
Tamaños: {{tallas}}
Material: {{material}}
Condición: {{condicion}}
Etiquetas: {{etiquetas}}
Stock: {{stock}}

📍 {{empresa}}
Dirección: {{direccion}}
Ubicación: {{ubicacion}}
Horario:
{{horario}}''';

  static const supportedPlaceholders = [
    '{{nombre}}',
    '{{precio}}',
    '{{descripcion}}',
    '{{sku}}',
    '{{stock}}',
    '{{colores}}',
    '{{tallas}}',
    '{{material}}',
    '{{marca}}',
    '{{condicion}}',
    '{{etiquetas}}',
    '{{direccion}}',
    '{{empresa}}',
    '{{horario}}',
    '{{ubicacion}}',
  ];

  MarketplaceTemplate copyWith({
    String? titleTemplate,
    String? bodyTemplate,
  }) {
    return MarketplaceTemplate(
      titleTemplate: titleTemplate ?? this.titleTemplate,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
    );
  }

  Map<String, dynamic> toJson() => {
        'titleTemplate': titleTemplate,
        'bodyTemplate': bodyTemplate,
      };

  factory MarketplaceTemplate.fromJson(Map<String, dynamic> json) =>
      MarketplaceTemplate(
        titleTemplate: json['titleTemplate'] as String? ?? defaultTitle,
        bodyTemplate: json['bodyTemplate'] as String? ?? defaultBody,
      );
}
