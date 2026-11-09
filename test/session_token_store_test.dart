import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora_mobile/services/session_token_store.dart';
import 'support/memory_secure_token_backend.dart';

void main() {
  late MemorySecureTokenBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = MemorySecureTokenBackend();
    SessionTokenStore.setBackendForTesting(backend);
  });

  test('migrates a legacy token into secure storage exactly once', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', 'legacy-token');

    final token = await SessionTokenStore.readToken();

    expect(token, 'legacy-token');
    expect(backend.token, 'legacy-token');
    expect(preferences.containsKey('token'), isFalse);
  });

  test('prefers secure token and removes a stale plaintext token', () async {
    backend.token = 'secure-token';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', 'stale-legacy-token');

    final token = await SessionTokenStore.readToken();

    expect(token, 'secure-token');
    expect(preferences.containsKey('token'), isFalse);
  });

  test('clears secure token and cached session values', () async {
    backend.token = 'secure-token';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', 'legacy-token');
    await preferences.setString('user', '{"id":1}');
    await preferences.setInt('background_at', 123);

    await SessionTokenStore.clearSession();

    expect(backend.token, isNull);
    expect(preferences.containsKey('token'), isFalse);
    expect(preferences.containsKey('user'), isFalse);
    expect(preferences.containsKey('background_at'), isFalse);
  });

  test('rejects an empty secure token', () {
    expect(
      () => SessionTokenStore.writeToken('  '),
      throwsArgumentError,
    );
  });
}
