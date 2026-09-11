import '../../../core/models/company_data.dart';
import '../../../core/models/marketplace_template.dart';
import '../../../core/models/product.dart';

class RenderedListing {
  const RenderedListing({required this.title, required this.body});
  final String title;
  final String body;
}

class MarketplaceTemplateRenderer {
  const MarketplaceTemplateRenderer();

  RenderedListing render({
    required MarketplaceTemplate template,
    required Product product,
    CompanyData? company,
  }) {
    final map = _buildMap(product, company ?? const CompanyData());
    return RenderedListing(
      title: _apply(template.titleTemplate, map),
      body: _apply(template.bodyTemplate, map),
    );
  }

  Map<String, String> _buildMap(Product p, CompanyData c) {
    return {
      'nombre': p.name,
      'precio': p.price.toStringAsFixed(p.price.truncateToDouble() == p.price ? 0 : 2),
      'descripcion': p.description,
      'sku': p.sku,
      'stock': '${p.stock}',
      'colores': p.colors.join(', '),
      'tallas': p.sizes.join(', '),
      'material': p.material,
      'marca': p.brand,
      'condicion': p.condition.labelEs,
      'etiquetas': p.tags.join(', '),
      'direccion': c.address,
      'empresa': c.name,
      'horario': c.hoursSummary(),
      'ubicacion': p.locationOverride.isNotEmpty
          ? p.locationOverride
          : (c.locationText.isNotEmpty
              ? c.locationText
              : [
                  if (c.latitude != null && c.longitude != null)
                    '${c.latitude}, ${c.longitude}',
                ].join()),
    };
  }

  String _apply(String template, Map<String, String> map) {
    var out = template;
    map.forEach((key, value) {
      out = out.replaceAll('{{$key}}', value);
    });
    return out.trim();
  }
}
