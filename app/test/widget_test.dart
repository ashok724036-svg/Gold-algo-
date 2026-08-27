import 'package:flutter_test/flutter_test.dart';
import 'package:goldscalper_pro/app.dart';

void main() {
  testWidgets('opens the local paper trading shell', (tester) async {
    await tester.pumpWidget(const GoldScalperApp());
    await tester.pumpAndSettle();
    expect(find.text('GoldScalper Pro'), findsOneWidget);
  });
}