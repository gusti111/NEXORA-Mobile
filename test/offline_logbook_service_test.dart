import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nexora_mobile/services/api_service.dart';
import 'package:nexora_mobile/services/offline_logbook_service.dart';
import 'package:nexora_mobile/services/offline_logbook_store.dart';
import 'package:nexora_mobile/services/session_token_store.dart';
import 'support/memory_secure_token_backend.dart';

void main() {
  late Directory tempDirectory;
  late OfflineLogbookStore store;
  late OfflineLogbookService service;
  late MemorySecureTokenBackend secureBackend;

  setUp(() async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({'user': '{"id": 1}'});

    secureBackend = MemorySecureTokenBackend();
    SessionTokenStore.setBackendForTesting(secureBackend);
    await SessionTokenStore.writeToken('offline-test-token');

    tempDirectory =
        await Directory.systemTemp.createTemp('nexora-outbox-service-');
    store = OfflineLogbookStore(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: '${tempDirectory.path}/offline.db',
    );
    service = OfflineLogbookService(
      store: store,
      documentsDirectory: tempDirectory,
    );
  });

  tearDown(() async {
    ApiService.setLogbookClientFactoryForTesting(null);
    await store.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  MockClient mockResponse(int statusCode, Map<String, dynamic> body) {
    return MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, endsWith('/logbooks'));
      return http.Response(
        jsonEncode(body),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  Future<Map<String, dynamic>> submit({File? photo}) {
    return service.submitLogbook(
      pklId: 17,
      judulKegiatan: 'Pemeriksaan jaringan',
      tanggalKegiatan: '2026-11-09',
      deskripsiKegiatan: 'Pengujian antrean offline.',
      foto: photo,
    );
  }

  test('removes a queued draft after an HTTP 200 idempotent replay', () async {
    final client = mockResponse(200, {
      'message': 'Logbook sudah diterima.',
      'duplicate': true,
      'data': {'id': 123},
    });

    ApiService.setLogbookClientFactoryForTesting(() => client);
    final result = await submit();

    expect(result['success'], isTrue);
    expect(result['queued'], isFalse);
    expect(await store.getQueueSummary(1), {
      'pending': 0,
      'failed': 0,
      'total': 0,
    });
  });

  test('moves permanent HTTP 422 responses to the failed queue', () async {
    final client = mockResponse(422, {
      'message': 'Tanggal kegiatan di luar periode PKL.',
      'errors': {
        'tanggal_kegiatan': ['Tanggal tidak valid.'],
      },
    });

    ApiService.setLogbookClientFactoryForTesting(() => client);
    final result = await submit();

    expect(result['success'], isFalse);
    expect(result['message'], 'Tanggal kegiatan di luar periode PKL.');
    expect(await store.getPending(1), isEmpty);
    expect(
      (await store.getFailed(1)).single['last_error'],
      'Tanggal kegiatan di luar periode PKL.',
    );
  });

  test('keeps HTTP 5xx drafts pending and preserves the photo extension',
      () async {
    final photo = File('${tempDirectory.path}/evidence.webp');
    await photo.writeAsBytes([1, 2, 3, 4]);

    final client = mockResponse(503, {
      'message': 'Server sedang tidak tersedia.',
    });

    ApiService.setLogbookClientFactoryForTesting(() => client);
    final result = await submit(photo: photo);

    expect(result['success'], isTrue);
    expect(result['queued'], isTrue);

    final pending = await store.getPending(1);
    expect(pending, hasLength(1));
    expect(pending.single['attempts'], 1);

    final storedPhotoPath = pending.single['foto_path'] as String;
    expect(storedPhotoPath, endsWith('.webp'));
    expect(await File(storedPhotoPath).exists(), isTrue);
  });
}
