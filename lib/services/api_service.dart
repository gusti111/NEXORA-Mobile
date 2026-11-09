import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'session_token_store.dart';

class ApiService {
  /// Override at build time with `--dart-define=API_BASE_URL=YOUR_API_BASE_URL`.
  /// The default targets the Android Studio emulator host machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Set by the root app to clear navigation when the API rejects a session.
  static Future<void> Function()? onUnauthorized;
  static void Function()? onAuthenticated;
  static bool _unauthorizedHandled = false;

  static Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode != 401 || _unauthorizedHandled) return;
    _unauthorizedHandled = true;
    await SessionTokenStore.clearSession();
    await onUnauthorized?.call();
  }

  /// Revalidates the bearer token and refreshes the cached user profile.
  /// A network failure is returned as an unknown status and does not erase the
  /// session; explicit 401/403 responses invalidate the local session.
  static Future<Map<String, dynamic>> validateSession() async {
    final result = await _getAuthenticated('/user');
    if (result['success'] == true) {
      final user = Map<String, dynamic>.from(result['data'] as Map);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user));
      return {'success': true, 'user': user, 'data': user, 'statusCode': 200};
    }

    final statusCode = result['statusCode'];
    if (statusCode == 403) {
      await SessionTokenStore.clearSession();
      await onUnauthorized?.call();
    }
    return result;
  }

  // ==========================================
  // AUTH
  // ==========================================
  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'login': login, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionTokenStore.writeToken(data['token'] as String);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        await prefs.remove('background_at');
        _unauthorizedHandled = false;
        onAuthenticated?.call();
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      }

      String message = data['message'] ?? 'Login gagal.';
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        if (errors.isNotEmpty) message = errors.values.first.first.toString();
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server. Periksa koneksi.',
      };
    }
  }

  static Future<void> logout() async {
    final token = await SessionTokenStore.readToken();

    try {
      if (token != null && token.isNotEmpty) {
        await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Local sign-out must still complete when the API is unreachable.
    } finally {
      await SessionTokenStore.clearSession();
      _unauthorizedHandled = false;
    }
  }

  // ==========================================
  // ADMIN
  // ==========================================
  static Future<Map<String, dynamic>> getAdminStatistics() async {
    return _getAuthenticated('/admin/statistics');
  }

  static Future<Map<String, dynamic>> getAdminUsers() async {
    return _getAuthenticated('/users');
  }

  static Future<Map<String, dynamic>> getAdminUserDetail(int userId) async {
    return _getAuthenticated('/admin/users/$userId');
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? nim,
    String? username,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'nim': ?nim,
          'username': ?username,
        }),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal membuat pengguna.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat membuat pengguna.'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminUser({
    required int userId,
    String? name,
    String? email,
    String? nim,
    String? username,
    String? role,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': ?name,
          'email': ?email,
          'nim': ?nim,
          'username': ?username,
          'role': ?role,
        }),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui pengguna.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat memperbarui pengguna.'};
    }
  }

  static Future<Map<String, dynamic>> resetAdminUserPassword({
    required int userId,
    required String password,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/reset-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal reset password.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat reset password.'};
    }
  }

  static Future<Map<String, dynamic>> toggleAdminUserStatus(int userId) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/toggle-status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal ubah status.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat ubah status.'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdminUser(int userId) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal hapus pengguna.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat hapus pengguna.'};
    }
  }

  // ==========================================
  // ADMIN: PKL
  // ==========================================
  static Future<Map<String, dynamic>> getAdminPkls() async {
    return _getAuthenticated('/admin/pkls');
  }

  static Future<Map<String, dynamic>> createAdminPkl({
    required int mahasiswaId,
    required int dosenId,
    required int korlapId,
    required String namaInstansi,
    String? alamatInstansi,
    required String tanggalMulai,
    String? tanggalSelesai,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/pkls'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mahasiswa_id': mahasiswaId,
          'dosen_id': dosenId,
          'korlap_id': korlapId,
          'nama_instansi': namaInstansi,
          'alamat_instansi': ?alamatInstansi,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': ?tanggalSelesai,
        }),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal membuat PKL.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat membuat PKL.'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminPkl({
    required int pklId,
    required int dosenId,
    required int korlapId,
    required String namaInstansi,
    String? alamatInstansi,
    required String tanggalMulai,
    String? tanggalSelesai,
    String? status,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/pkls/$pklId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'dosen_id': dosenId,
          'korlap_id': korlapId,
          'nama_instansi': namaInstansi,
          'alamat_instansi': ?alamatInstansi,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': ?tanggalSelesai,
          'status': ?status,
        }),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memperbarui PKL.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat memperbarui PKL.'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdminPkl(int pklId) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/pkls/$pklId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal hapus PKL.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat hapus PKL.'};
    }
  }

  static Future<Map<String, dynamic>> getAdminLogbooks({String? status}) async {
    final endpoint = status != null && status != 'semua'
        ? '/admin/logbooks?status=$status'
        : '/admin/logbooks';
    return _getAuthenticated(endpoint);
  }

  // ==========================================
  // MAHASISWA
  // ==========================================
  static Future<Map<String, dynamic>> getStudentPkls() async {
    return _getAuthenticated('/pkls');
  }

  static Future<Map<String, dynamic>> getStudentLogbooks() async {
    return _getAuthenticated('/logbooks');
  }

  static Future<Map<String, dynamic>> getStudentStatistics() async {
    return _getAuthenticated('/logbooks/statistics');
  }

  static Future<Map<String, dynamic>> getLogbookHistory(int logbookId) async {
    return _getAuthenticated('/logbooks/$logbookId/history');
  }

  static Future<Map<String, dynamic>> createStudentLogbook({
    required int pklId,
    required String judulKegiatan,
    required String tanggalKegiatan,
    required String deskripsiKegiatan,
    File? foto,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/logbooks'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['pkl_id'] = pklId.toString();
      request.fields['judul_kegiatan'] = judulKegiatan;
      request.fields['tanggal_kegiatan'] = tanggalKegiatan;
      request.fields['deskripsi_kegiatan'] = deskripsiKegiatan;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (foto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', foto.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim logbook.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat mengirim logbook. Periksa koneksi server.',
      };
    }
  }

  static Future<Map<String, dynamic>> resubmitStudentLogbook({
    required int logbookId,
    required String judulKegiatan,
    required String deskripsiKegiatan,
    File? foto,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/logbooks/$logbookId/resubmit'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['_method'] = 'PUT';
      request.fields['judul_kegiatan'] = judulKegiatan;
      request.fields['deskripsi_kegiatan'] = deskripsiKegiatan;
      if (foto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', foto.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      await _handleUnauthorized(response);
      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesi login tidak valid. Silakan login kembali.',
          'statusCode': 401,
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengirim ulang logbook.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat mengirim ulang. Periksa koneksi server.',
      };
    }
  }

  // ==========================================
  // DOSEN
  // ==========================================
  static Future<Map<String, dynamic>> getDosenLogbooks() async {
    return _getAuthenticated('/dosen/logbooks');
  }

  static Future<Map<String, dynamic>> getDosenMahasiswa() async {
    return _getAuthenticated('/dosen/mahasiswa');
  }

  static Future<Map<String, dynamic>> getLogbookHistoryDosen(
    int logbookId,
  ) async {
    return _getAuthenticated('/logbooks/$logbookId/history');
  }

  static Future<Map<String, dynamic>> reviewDosenLogbook({
    required int logbookId,
    required String status,
    String? komentar,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/dosen/logbooks/$logbookId/review'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'komentar': ?komentar,
        }),
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memproses logbook.',
        'errors': data['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat memproses logbook. Periksa koneksi server.',
      };
    }
  }

  // ==========================================
  // KORLAP
  // ==========================================
  static Future<Map<String, dynamic>> getKorlapStatistics() async {
    return _getAuthenticated('/korlap/statistics');
  }

  static Future<Map<String, dynamic>> getKorlapLogbooks() async {
    return _getAuthenticated('/korlap/logbooks');
  }

  static Future<Map<String, dynamic>> getKorlapMahasiswa() async {
    return _getAuthenticated('/korlap/mahasiswa');
  }

  static Future<Map<String, dynamic>> completeKorlapPkl(int pklId) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/korlap/pkls/$pklId/complete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal menyelesaikan PKL.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat menyelesaikan PKL. Periksa koneksi server.',
      };
    }
  }

  static Future<Map<String, dynamic>> downloadKorlapExport({
    required String type,
    required String savePath,
  }) async {
    try {
      final token = await SessionTokenStore.readToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final endpoint = type == 'excel'
          ? '/korlap/logbooks/export/excel'
          : '/korlap/logbooks/export/pdf';

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Gagal mengunduh file (status ${response.statusCode}).',
        };
      }

      String filename = type == 'excel'
          ? 'laporan-logbook-korlap.xlsx'
          : 'laporan-logbook-korlap.pdf';

      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null) {
        final match =
            RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
        if (match != null) filename = match.group(1)!.trim();
      }

      final file = File('$savePath/$filename');
      await file.writeAsBytes(response.bodyBytes);

      return {
        'success': true,
        'filePath': file.path,
        'filename': filename,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengunduh file: $e'};
    }
  }

  // ==========================================
  // HELPER
  // ==========================================
  static Future<Map<String, dynamic>> _getAuthenticated(
    String endpoint,
  ) async {
    try {
      final token = await SessionTokenStore.readToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Sesi login tidak ditemukan.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await _handleUnauthorized(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mengambil data dari server.',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat mengambil data. Periksa koneksi server.',
        'statusCode': null,
      };
    }
  }
}