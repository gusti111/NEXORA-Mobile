import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('NEXORA opens the login screen without a saved session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NexoraApp());
    await tester.pumpAndSettle();

    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Selamat Datang!'), findsOneWidget);
  });
}
