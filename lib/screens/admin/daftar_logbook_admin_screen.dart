import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/secure_logbook_image.dart';

class DaftarLogbookAdminScreen extends StatefulWidget {
  const DaftarLogbookAdminScreen({super.key});

  @override
  State<DaftarLogbookAdminScreen> createState() =>
      _DaftarLogbookAdminScreenState();
}

class _DaftarLogbookAdminScreenState extends State<DaftarLogbookAdminScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> logbooks = [];
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await ApiService.getAdminLogbooks(status: _filter);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Gagal memuat logbook.');
      }
      if (!mounted) return;
      setState(() {
        logbooks = result['data'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return Colors.green;
      case 'revision_requested':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Disetujui';
      case 'revision_requested':
        return 'Perlu Revisi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Manajemen Logbook'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('semua', 'Semua'),
                  _chip('pending', 'Menunggu'),
                  _chip('approved', 'Disetujui'),
                  _chip('revision_requested', 'Revisi'),
                  _chip('rejected', 'Ditolak'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF145C4B),
                      ),
                    )
                  : errorMessage != null
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 100),
                            const Icon(Icons.error_outline,
                                size: 50, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: _load,
                                child: const Text('Coba Lagi'),
                              ),
                            ),
                          ],
                        )
                      : logbooks.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Icon(Icons.menu_book_outlined,
                                    size: 65, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada logbook.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: logbooks.length,
                              itemBuilder: (context, index) {
                                final item = Map<String, dynamic>.from(
                                  logbooks[index],
                                );
                                return _buildCard(item);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isActive = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) {
          setState(() => _filter = key);
          _load();
        },
        selectedColor: const Color(0xFF145C4B),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final mahasiswa = item['pkl']?['mahasiswa'] ?? {};
    final dosen = item['pkl']?['dosen'] ?? {};
    final judul = item['judul_kegiatan'];
    final foto = item['foto'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mahasiswa['name'] ?? 'Mahasiswa',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Dosen: ${dosen['name'] ?? '-'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (judul != null && judul.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              judul.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            item['tanggal_kegiatan'] ?? '-',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            item['deskripsi_kegiatan'] ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (foto != null && foto.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SecureLogbookImage(
                logbookId: int.parse(item['id'].toString()),
                height: 100,
                width: double.infinity,
              ),
            ),
          ],
        ],
      ),
    );
  }
}