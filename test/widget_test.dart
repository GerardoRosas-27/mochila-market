import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mochila_market/app.dart';

void main() {
  testWidgets('App muestra tienda pública sin login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MochilaMarketApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Tienda'), findsWidgets);
  });
}
