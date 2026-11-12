import 'package:flutter_test/flutter_test.dart';
import 'package:masraf_hesabi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MasrafHesabiApp());
    expect(find.byType(MasrafHesabiApp), findsOneWidget);
  });
}
