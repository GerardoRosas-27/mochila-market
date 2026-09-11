import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mochila_market/app.dart';

void main() {
  testWidgets('App muestra puerta de login local', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MochilaMarketApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Sin usuario registrado: registro; con sesión: shell. En test limpio → login/registro.
    expect(find.textContaining('MochilaMarket'), findsWidgets);
  });
}
