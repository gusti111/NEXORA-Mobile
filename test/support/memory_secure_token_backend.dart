import 'package:nexora_mobile/services/session_token_store.dart';

class MemorySecureTokenBackend implements SecureTokenBackend {
  String? token;
  bool failRead = false;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('Secure storage is unavailable.');
    return token;
  }

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> delete() async {
    token = null;
  }
}
