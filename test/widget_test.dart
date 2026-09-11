import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mochila_market/app.dart';

void main() {
  testWidgets('App arranca con shell de navegación', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MochilaMarketApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fotos'), findsWidgets);
  });
}
