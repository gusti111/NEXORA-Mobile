import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Durable local cache and outbox. Authentication credentials are never stored
/// in this database; every queue item is scoped to the signed-in user id.
class OfflineLogbookStore {
  OfflineLogbookStore({
    DatabaseFactory? databaseFactoryOverride,
    this.databasePathOverride,
  }) : _databaseFactory = databaseFactoryOverride ?? databaseFactory;

  final DatabaseFactory _databaseFactory;
  final String? databasePathOverride;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final path = databasePathOverride ?? 'nexora_offline.db';
    _database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE pending_logbooks (
              local_id TEXT PRIMARY KEY,
              user_id INTEGER NOT NULL,
              pkl_id INTEGER NOT NULL,
              judul_kegiatan TEXT NOT NULL,
              tanggal_kegiatan TEXT NOT NULL,
              deskripsi_kegiatan TEXT NOT NULL,
              foto_path TEXT,
              latitude REAL,
              longitude REAL,
              status TEXT NOT NULL DEFAULT 'pending',
              attempts INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_pending_logbooks_user_status
            ON pending_logbooks(user_id, status, created_at)
          ''');

          await db.execute('''
            CREATE TABLE cached_pkls (
              user_id INTEGER NOT NULL,
              pkl_id INTEGER NOT NULL,
              payload TEXT NOT NULL,
              PRIMARY KEY(user_id, pkl_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE cached_logbooks (
              user_id INTEGER NOT NULL,
              logbook_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              PRIMARY KEY(user_id, logbook_id)
            )
          ''');
        },
      ),
    );

    return _database!;
  }

  Future<void> cachePkls(
    int userId,
    List<Map<String, Object?>> records,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cached_pkls', where: 'user_id = ?', whereArgs: [userId]);
      for (final record in records) {
        final pklId = int.tryParse(record['id'].toString());
        if (pklId == null) continue;
        await txn.insert(
          'cached_pkls',
          {
            'user_id': userId,
            'pkl_id': pklId,
            'payload': jsonEncode(record),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCachedPkls(int userId) async {
    final db = await database;
    final rows = await db.query(
      'cached_pkls',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'pkl_id DESC',
    );
    return rows
        .map((row) => Map<String, dynamic>.from(
              jsonDecode(row['payload'] as String) as Map,
            ))
        .toList(growable: false);
  }

  Future<void> cacheLogbooks(
    int userId,
    List<Map<String, Object?>> records,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'cached_logbooks',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final record in records) {
        final id = record['id'];
        if (id == null) continue;
        await txn.insert(
          'cached_logbooks',
          {
            'user_id': userId,
            'logbook_id': id.toString(),
            'payload': jsonEncode(record),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCachedLogbooks(int userId) async {
    final db = await database;
    final rows = await db.query(
      'cached_logbooks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logbook_id DESC',
    );
    return rows
        .map((row) => Map<String, dynamic>.from(
              jsonDecode(row['payload'] as String) as Map,
            ))
        .toList(growable: false);
  }

  Future<void> enqueue(Map<String, Object?> record) async {
    final db = await database;
    await db.insert(
      'pending_logbooks',
      record,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, Object?>?> getPendingById(String localId) async {
    final db = await database;
    final rows = await db.query(
      'pending_logbooks',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<List<Map<String, Object?>>> getPending(int userId) async {
    final db = await database;
    final rows = await db.query(
      'pending_logbooks',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> getFailed(int userId) async {
    final db = await database;
    final rows = await db.query(
      'pending_logbooks',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'failed'],
      orderBy: 'created_at DESC',
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  Future<void> markAttempt(
    String localId, {
    required String? error,
  }) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE pending_logbooks
      SET attempts = attempts + 1, last_error = ?
      WHERE local_id = ?
      ''',
      [error, localId],
    );
  }

  Future<void> markFailed(String localId, String error) async {
    final db = await database;
    await db.update(
      'pending_logbooks',
      {'status': 'failed', 'last_error': error},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteFailed(String localId, int userId) async {
    final db = await database;
    await db.delete(
      'pending_logbooks',
      where: 'local_id = ? AND user_id = ? AND status = ?',
      whereArgs: [localId, userId, 'failed'],
    );
  }

  Future<void> retryFailed(int userId) async {
    final db = await database;
    await db.update(
      'pending_logbooks',
      {'status': 'pending', 'last_error': null},
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'failed'],
    );
  }

  Future<void> deletePending(String localId) async {
    final db = await database;
    await db.delete(
      'pending_logbooks',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<Map<String, int>> getQueueSummary(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT status, COUNT(*) AS total
      FROM pending_logbooks
      WHERE user_id = ?
      GROUP BY status
      ''',
      [userId],
    );
    final summary = {'pending': 0, 'failed': 0, 'total': 0};
    for (final row in rows) {
      final status = row['status']?.toString();
      final count = (row['total'] as int?) ?? 0;
      if (status != null && summary.containsKey(status)) {
        summary[status] = count;
      }
      summary['total'] = summary['total']! + count;
    }
    return summary;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
