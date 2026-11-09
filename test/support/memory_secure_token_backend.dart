import 'package:nexora_mobile/services/session_token_store.dart';

class MemorySecureTokenBackend implements SecureTokenBackend {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> delete() async {
    token = null;
  }
}
