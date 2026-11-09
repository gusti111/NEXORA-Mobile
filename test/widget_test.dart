import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_mobile/main.dart';

void main() {
  testWidgets('NEXORA app can be created', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraApp());

    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
