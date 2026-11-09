import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_mobile/main.dart';
import 'package:nexora_mobile/services/session_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_secure_token_backend.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionTokenStore.setBackendForTesting(MemorySecureTokenBackend());
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
