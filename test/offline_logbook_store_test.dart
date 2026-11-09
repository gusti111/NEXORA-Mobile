import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nexora_mobile/services/offline_logbook_store.dart';

void main() {
  late Directory tempDirectory;
  late OfflineLogbookStore store;

  setUp(() async {
    sqfliteFfiInit();
    tempDirectory = await Directory.systemTemp.createTemp('nexora-offline-test-');
    store = OfflineLogbookStore(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePathOverride: tempDirectory.path + '/offline.db',
    );
  });

  tearDown(() async {
    await store.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Map<String, Object?> queueItem({
    required String id,
    required int userId,
    String status = 'pending',
  }) {
    return {
      'local_id': id,
      'user_id': userId,
      'pkl_id': 10,
      'judul_kegiatan': 'Pemeriksaan jaringan',
      'tanggal_kegiatan': '2026-11-09',
      'deskripsi_kegiatan': 'Menguji koneksi lokal.',
      'foto_path': null,
      'latitude': null,
      'longitude': null,
      'status': status,
      'attempts': 0,
      'last_error': null,
      'created_at': DateTime.utc(2026, 11, 9).toIso8601String(),
    };
  }

  test('persists queued submissions and isolates them by account', () async {
    await store.enqueue(queueItem(id: 'offline-a', userId: 1));
    await store.enqueue(queueItem(id: 'offline-b', userId: 2));

    expect((await store.getPending(1)).map((e) => e['local_id']), ['offline-a']);
    expect((await store.getPending(2)).map((e) => e['local_id']), ['offline-b']);
    expect(await store.getQueueSummary(1), {
      'pending': 1,
      'failed': 0,
      'total': 1,
    });
  });

  test('stores cached PKL data and keeps each user separate', () async {
    await store.cachePkls(1, [
      {'id': 10, 'nama_instansi': 'Instansi A', 'status': 'berlangsung'},
    ]);
    await store.cachePkls(2, [
      {'id': 20, 'nama_instansi': 'Instansi B', 'status': 'berlangsung'},
    ]);

    expect((await store.getCachedPkls(1)).single['id'], 10);
    expect((await store.getCachedPkls(2)).single['id'], 20);
  });

  test('marks invalid queue items as failed and allows explicit retry', () async {
    await store.enqueue(queueItem(id: 'offline-a', userId: 1));
    await store.markAttempt('offline-a', error: 'Validation failed');
    await store.markFailed('offline-a', 'Tanggal kegiatan di luar periode PKL.');

    expect(await store.getPending(1), isEmpty);
    expect((await store.getFailed(1)).single['last_error'],
        'Tanggal kegiatan di luar periode PKL.');

    await store.retryFailed(1);

    expect((await store.getPending(1)).single['status'], 'pending');
    expect(await store.getFailed(1), isEmpty);
  });

  test('caches last known server logbooks for offline reading', () async {
    await store.cacheLogbooks(7, [
      {'id': 91, 'judul_kegiatan': 'Logbook tersimpan', 'status': 'approved'},
    ]);

    final cached = await store.getCachedLogbooks(7);
    expect(cached.single['id'], 91);
    expect(cached.single['status'], 'approved');
  });
}
