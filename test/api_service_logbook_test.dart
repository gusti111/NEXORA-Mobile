import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:nexora_mobile/services/api_service.dart';
import 'package:nexora_mobile/services/session_token_store.dart';
import 'support/memory_secure_token_backend.dart';

void main() {
  late MemorySecureTokenBackend backend;

  setUp(() async {
    backend = MemorySecureTokenBackend();
    SessionTokenStore.setBackendForTesting(backend);
    await SessionTokenStore.writeToken('test-session-token');
  });

  Future<Map<String, dynamic>> submitWithStatus(int statusCode) async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/logbooks'));
      expect(
        request.headers['Authorization'],
        'Bearer test-session-token',
      );
      return http.Response(
        jsonEncode({
          'message': 'Logbook sudah diterima.',
          'duplicate': statusCode == 200,
          'data': {'id': 123},
        }),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    });

    return http.runWithClient(
      () => ApiService.createStudentLogbook(
        pklId: 17,
        judulKegiatan: 'Pemeriksaan jaringan',
        tanggalKegiatan: '2026-11-09',
        deskripsiKegiatan: 'Pengujian idempotensi pengiriman.',
        idempotencyKey: '9bb1f8f4-4b58-4c98-a2e1-8aa6d28b1002',
      ),
      () => client,
    );
  }

  test('accepts HTTP 200 as a successful idempotent replay', () async {
    final result = await submitWithStatus(200);

    expect(result['success'], isTrue);
    expect(result['duplicate'], isTrue);
    expect(result['statusCode'], 200);
    expect((result['data'] as Map)['id'], 123);
  });

  test('accepts HTTP 201 as a newly created logbook', () async {
    final result = await submitWithStatus(201);

    expect(result['success'], isTrue);
    expect(result['duplicate'], isFalse);
    expect(result['statusCode'], 201);
  });

  test('returns validation status for permanent server rejection', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'message': 'Tanggal kegiatan di luar periode PKL.',
          'errors': {'tanggal_kegiatan': ['Tanggal tidak valid.']},
        }),
        422,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await http.runWithClient(
      () => ApiService.createStudentLogbook(
        pklId: 17,
        judulKegiatan: 'Pemeriksaan jaringan',
        tanggalKegiatan: '2026-11-09',
        deskripsiKegiatan: 'Pengujian validasi tanggal.',
        idempotencyKey: 'd22a3f0a-8d9a-4a94-a20c-0a25a60d1001',
      ),
      () => client,
    );

    expect(result['success'], isFalse);
    expect(result['statusCode'], 422);
    expect(result['retryable'], isFalse);
    expect(result['message'], 'Tanggal kegiatan di luar periode PKL.');
  });
}
