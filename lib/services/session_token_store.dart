import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal abstraction so token migration and session behavior can be tested
/// without invoking platform secure-storage channels.
abstract interface class SecureTokenBackend {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class FlutterSecureTokenBackend implements SecureTokenBackend {
  FlutterSecureTokenBackend({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'nexora_access_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class SessionTokenStore {
  SessionTokenStore._();

  static SecureTokenBackend _backend = FlutterSecureTokenBackend();

  /// Test seam for replacing platform storage with an in-memory backend.
  @visibleForTesting
  static void setBackendForTesting(SecureTokenBackend backend) {
    _backend = backend;
  }

  @visibleForTesting
  static void resetBackendForTesting() {
    _backend = FlutterSecureTokenBackend();
  }

  /// Reads the encrypted token and migrates the legacy SharedPreferences token
  /// exactly once, removing the plaintext copy after a successful write.
  static Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    String? secureToken;

    try {
      secureToken = await _backend.read();
    } catch (_) {
      // A token that cannot be decrypted must not leave the app stuck in an
      // invalid-session loop. Best-effort removal is followed by cache cleanup.
      try {
        await _backend.delete();
      } catch (_) {
        // The platform may be unable to access the key store at this moment.
      }
      await preferences.remove('token');
      await preferences.remove('user');
      await preferences.remove('background_at');
      return null;
    }

    if (secureToken != null && secureToken.isNotEmpty) {
      if (preferences.containsKey('token')) {
        await preferences.remove('token');
      }
      return secureToken;
    }

    final legacyToken = preferences.getString('token');
    if (legacyToken == null || legacyToken.isEmpty) {
      return null;
    }

    await _backend.write(legacyToken);
    await preferences.remove('token');
    return legacyToken;
  }

  static Future<void> writeToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty.');
    }
    await _backend.write(token);
  }

  /// Clears both secure token storage and legacy/session cache values.
  static Future<void> clearSession() async {
    try {
      await _backend.delete();
    } finally {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('token');
      await preferences.remove('user');
      await preferences.remove('background_at');
    }
  }
}
