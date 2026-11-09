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

  tearDown(() {
    ApiService.setLogbookClientFactoryForTesting(null);
  });

  Future<Map<String, dynamic>> submitWithStatus(
    int statusCode, {
    Map<String, dynamic>? responseBody,
    void Function(http.BaseRequest request)? captureRequest,
  }) async {
    ApiService.setLogbookClientFactoryForTesting(
      () => MockClient((request) async {
        captureRequest?.call(request);
        return http.Response(
          jsonEncode(responseBody ?? {
            'message': 'Logbook sudah diterima.',
            'duplicate': statusCode == 200,
            'data': {'id': 123},
          }),
          statusCode,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    return ApiService.createStudentLogbook(
      pklId: 17,
      judulKegiatan: 'Pemeriksaan jaringan',
      tanggalKegiatan: '2026-11-09',
      deskripsiKegiatan: 'Pengujian idempotensi pengiriman.',
      idempotencyKey: '9bb1f8f4-4b58-4c98-a2e1-8aa6d28b1002',
    );
  }

  test('accepts HTTP 200 as a successful idempotent replay', () async {
    http.BaseRequest? captured;
    final result = await submitWithStatus(
      200,
      captureRequest: (request) => captured = request,
    );

    expect(captured?.method, 'POST');
    expect(captured?.url.path, endsWith('/logbooks'));
    final authorizationEntries = captured?.headers.entries
        .where((entry) => entry.key.toLowerCase() == 'authorization')
        .toList();
    final authorization = authorizationEntries == null ||
            authorizationEntries.isEmpty
        ? null
        : authorizationEntries.first.value;
    expect(authorization, 'Bearer test-session-token');

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
    final result = await submitWithStatus(
      422,
      responseBody: {
        'message': 'Tanggal kegiatan di luar periode PKL.',
        'errors': {'tanggal_kegiatan': ['Tanggal tidak valid.']},
      },
    );

    expect(result['success'], isFalse);
    expect(result['statusCode'], 422);
    expect(result['retryable'], isFalse);
    expect(result['message'], 'Tanggal kegiatan di luar periode PKL.');
  });
}
