import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'revisi_logbook_screen.dart';

class DetailLogbookMahasiswaScreen extends StatefulWidget {
  final Map<String, dynamic> logbook;

  const DetailLogbookMahasiswaScreen({super.key, required this.logbook});

  @override
  State<DetailLogbookMahasiswaScreen> createState() =>
      _DetailLogbookMahasiswaScreenState();
}

class _DetailLogbookMahasiswaScreenState
    extends State<DetailLogbookMahasiswaScreen> {
  Map<String, dynamic>? history;
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await ApiService.getLogbookHistory(widget.logbook['id']);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        history = Map<String, dynamic>.from(result['data'] ?? {});
      }
      isLoadingHistory = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
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

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'revision_requested':
        return 'Perlu Revisi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Review';
    }
  }

  String _formatTanggal(dynamic tgl) {
    if (tgl == null) return '-';
    try {
      final date = DateTime.parse(tgl.toString());
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final logbook = widget.logbook;
    final status = logbook['status'] ?? 'pending';
    final foto = logbook['foto'];
    final judul = logbook['judul_kegiatan'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Logbook'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (judul != null && judul.toString().isNotEmpty) ...[
                      Text(
                        judul.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Tanggal Kegiatan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTanggal(logbook['tanggal_kegiatan']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi Kegiatan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      logbook['deskripsi_kegiatan'] ?? '-',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    if (foto != null && foto.toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Foto Dokumentasi',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'http://192.168.137.1:8000/storage/$foto',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 100,
                            alignment: Alignment.center,
                            color: Colors.grey.shade200,
                            child: const Text(
                              'Foto tidak dapat dimuat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (logbook['catatan_dosen'] != null &&
                  logbook['catatan_dosen'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Catatan Dosen',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(logbook['catatan_dosen'].toString()),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                'Riwayat Pemeriksaan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF176B4D)),
                  ),
                )
              else if (history == null ||
                  (history!['riwayat_pemeriksaan'] as List?)?.isEmpty != false)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Belum ada riwayat pemeriksaan.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              else
                ...(history!['riwayat_pemeriksaan'] as List).map((item) {
                  final itemMap = Map<String, dynamic>.from(item);
                  final itemStatus = itemMap['status'] ?? 'pending';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _statusColor(itemStatus),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(itemStatus),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(itemStatus),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTanggal(itemMap['created_at']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dosen: ${itemMap['dosen']?['name'] ?? '-'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        if (itemMap['komentar'] != null &&
                            itemMap['komentar'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            itemMap['komentar'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

              if (status == 'revision_requested') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                                    child: ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final updated = await navigator.push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RevisiLogbookScreen(logbook: logbook),
                        ),
                      );
                      if (!mounted) return;
                      if (updated == true) {
                        navigator.pop(true);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Kirim Ulang Perbaikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}