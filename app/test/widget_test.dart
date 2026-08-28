import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldscalper_pro/app.dart';

void main() {
  testWidgets('opens the local paper trading shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GoldScalperApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good morning, trader'), findsOneWidget);
  });
}