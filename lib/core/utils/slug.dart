/// Genera un slug estable y legible para URLs públicas `/p/:slug`.
String slugify(String title, String id) {
  var base = title
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
  if (base.isEmpty) base = 'mochila';
  if (base.length > 48) base = base.substring(0, 48).replaceAll(RegExp(r'-$'), '');
  final short = id.length >= 8 ? id.substring(0, 8) : id;
  return '$base-$short';
}
