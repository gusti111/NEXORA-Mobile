import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api_service.dart';
import 'offline_logbook_store.dart';

class OfflineLogbookService {
  OfflineLogbookService({
    OfflineLogbookStore? store,
    Directory? documentsDirectory,
  })  : store = store ?? OfflineLogbookStore(),
        _documentsDirectory = documentsDirectory;

  static final OfflineLogbookService instance = OfflineLogbookService();

  final OfflineLogbookStore store;
  final Directory? _documentsDirectory;
  final Uuid _uuid = const Uuid();
  bool _syncRunning = false;

  Future<int?> currentUserId() async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString('user');
    if (rawUser == null) return null;
    try {
      final id = (jsonDecode(rawUser) as Map)['id'];
      return int.tryParse(id.toString());
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadStudentPkls() async {
    final userId = await currentUserId();
    if (userId == null) return const [];

    final result = await ApiService.getStudentPkls();
    if (result['success'] == true) {
      final records = (result['data'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
      await store.cachePkls(userId, records);
      return records.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return store.getCachedPkls(userId);
  }

  Future<List<Map<String, dynamic>>> loadStudentLogbooks() async {
    final userId = await currentUserId();
    if (userId == null) return const [];

    final result = await ApiService.getStudentLogbooks();
    if (result['success'] == true) {
      final records = (result['data'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
      await store.cacheLogbooks(userId, records);
      return records.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    return store.getCachedLogbooks(userId);
  }

  Future<Map<String, dynamic>> submitLogbook({
    required int pklId,
    required String judulKegiatan,
    required String tanggalKegiatan,
    required String deskripsiKegiatan,
    File? foto,
    double? latitude,
    double? longitude,
  }) async {
    final userId = await currentUserId();
    if (userId == null) {
      return {
        'success': false,
        'message': 'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      };
    }

    final localId = _uuid.v4();
    String? savedPhotoPath;

    try {
      if (foto != null) {
        savedPhotoPath = await _persistPhoto(foto, userId, localId);
      }

      await store.enqueue({
        'local_id': localId,
        'user_id': userId,
        'pkl_id': pklId,
        'judul_kegiatan': judulKegiatan,
        'tanggal_kegiatan': tanggalKegiatan,
        'deskripsi_kegiatan': deskripsiKegiatan,
        'foto_path': savedPhotoPath,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'pending',
        'attempts': 0,
        'last_error': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error) {
      if (savedPhotoPath != null) {
        await _deletePhoto(savedPhotoPath);
      }
      return {
        'success': false,
        'message': 'Draft tidak dapat disimpan di perangkat: $error',
      };
    }

    await syncPendingLogbooks();
    final item = await store.getPendingById(localId);

    if (item == null) {
      return {
        'success': true,
        'queued': false,
        'message': 'Logbook berhasil dikirim ke server.',
      };
    }

    if (item['status'] == 'failed') {
      return {
        'success': false,
        'queued': false,
        'message': item['last_error'] ??
            'Server menolak logbook. Periksa kembali isi laporan.',
      };
    }

    return {
      'success': true,
      'queued': true,
      'message':
          'Logbook tersimpan di perangkat dan menunggu sinkronisasi.',
      'local_id': localId,
    };
  }

  Future<Map<String, int>> syncPendingLogbooks() async {
    final userId = await currentUserId();
    if (userId == null) {
      return {'pending': 0, 'failed': 0, 'total': 0, 'synced': 0};
    }

    if (_syncRunning) {
      return store.getQueueSummary(userId);
    }

    _syncRunning = true;
    var synced = 0;
    try {
      final pendingItems = await store.getPending(userId);
      for (final item in pendingItems) {
        final localId = item['local_id'] as String;
        final result = await ApiService.createStudentLogbook(
          pklId: item['pkl_id'] as int,
          judulKegiatan: item['judul_kegiatan'] as String,
          tanggalKegiatan: item['tanggal_kegiatan'] as String,
          deskripsiKegiatan: item['deskripsi_kegiatan'] as String,
          idempotencyKey: localId,
          foto: item['foto_path'] == null
              ? null
              : File(item['foto_path'] as String),
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
        );

        await store.markAttempt(
          localId,
          error: result['success'] == true
              ? null
              : result['message']?.toString(),
        );

        if (result['success'] == true) {
          final photoPath = item['foto_path']?.toString();
          await store.deletePending(localId);
          if (photoPath != null) await _deletePhoto(photoPath);
          synced++;
          continue;
        }

        final statusCode = result['statusCode'];

        // Authentication, throttling, timeouts, and server errors should
        // remain pending so the same idempotency key can be retried later.
        if (statusCode == 401 ||
            statusCode == 403 ||
            statusCode == 408 ||
            statusCode == 425 ||
            statusCode == 429 ||
            statusCode == null ||
            (statusCode is int && statusCode >= 500)) {
          break;
        }

        // Other 4xx responses are permanent for this payload/account/route.
        // Keep them visible as failed drafts instead of retrying on every app
        // resume forever.
        if (statusCode is int && statusCode >= 400 && statusCode < 500) {
          await store.markFailed(
            localId,
            result['message']?.toString() ??
                'Server menolak data logbook (HTTP $statusCode).',
          );
        }
      }
    } finally {
      _syncRunning = false;
    }

    final summary = await store.getQueueSummary(userId);
    summary['synced'] = synced;
    return summary;
  }

  Future<bool> deleteFailedDraft(String localId) async {
    final userId = await currentUserId();
    if (userId == null) return false;

    final item = await store.getPendingById(localId);
    if (item == null ||
        item['user_id'] != userId ||
        item['status'] != 'failed') {
      return false;
    }

    final photoPath = item['foto_path']?.toString();
    await store.deleteFailed(localId, userId);
    if (photoPath != null) await _deletePhoto(photoPath);
    return true;
  }

  Future<Map<String, int>> retryFailedLogbooks() async {
    final userId = await currentUserId();
    if (userId == null) {
      return {'pending': 0, 'failed': 0, 'total': 0, 'synced': 0};
    }
    await store.retryFailed(userId);
    return syncPendingLogbooks();
  }

  Future<List<Map<String, dynamic>>> getQueueItems() async {
    final userId = await currentUserId();
    if (userId == null) return const [];

    final pending = await store.getPending(userId);
    final failed = await store.getFailed(userId);
    return [...pending, ...failed].map((item) {
      final failedItem = item['status'] == 'failed';
      return <String, dynamic>{
        'id': 'local:${item['local_id']}',
        'local_id': item['local_id'],
        'is_local': true,
        'status': failedItem ? 'sync_failed' : 'offline_pending',
        'tanggal_kegiatan': item['tanggal_kegiatan'],
        'judul_kegiatan': item['judul_kegiatan'],
        'deskripsi_kegiatan': item['deskripsi_kegiatan'],
        'foto_path': item['foto_path'],
        'foto': null,
        'catatan_dosen': failedItem ? item['last_error'] : null,
        'created_at': item['created_at'],
      };
    }).toList(growable: false);
  }

  Future<Map<String, int>> getQueueSummary() async {
    final userId = await currentUserId();
    if (userId == null) return {'pending': 0, 'failed': 0, 'total': 0};
    return store.getQueueSummary(userId);
  }

  Future<List<Map<String, Object?>>> getFailedLogbooks() async {
    final userId = await currentUserId();
    if (userId == null) return const [];
    return store.getFailed(userId);
  }

  Future<String> _persistPhoto(File source, int userId, String localId) async {
    if (!await source.exists()) {
      throw StateError('File foto tidak ditemukan.');
    }
    final documents =
        _documentsDirectory ?? await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}/nexora_offline/$userId',
    );
    await directory.create(recursive: true);
    final fileName = source.uri.pathSegments.isEmpty
        ? ''
        : source.uri.pathSegments.last;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    if (!supportedExtensions.contains(extension)) {
      throw StateError(
        'Format foto tidak didukung. Gunakan JPG, JPEG, PNG, atau WEBP.',
      );
    }

    final target = File('${directory.path}/$localId.$extension');
    await source.copy(target.path);
    return target.path;
  }

  Future<void> _deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A cleanup failure must not block queue state changes.
    }
  }
}
