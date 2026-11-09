import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';

class DetailLogbookKorlapScreen extends StatefulWidget {
  final Map<String, dynamic> logbook;
  const DetailLogbookKorlapScreen({super.key, required this.logbook});

  @override
  State<DetailLogbookKorlapScreen> createState() =>
      _DetailLogbookKorlapScreenState();
}

class _DetailLogbookKorlapScreenState
    extends State<DetailLogbookKorlapScreen> {
  Map<String, dynamic>? history;
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result =
        await ApiService.getLogbookHistory(widget.logbook['id']);
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
        return 'Menunggu';
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

  Future<void> _bukaMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logbook = widget.logbook;
    final status = logbook['status'] ?? 'pending';
    final foto = logbook['foto'];
    final latitude = logbook['latitude'];
    final longitude = logbook['longitude'];
    final hasGps = latitude != null && longitude != null;
    final mahasiswa = logbook['pkl']?['mahasiswa'] ?? {};
    final dosen = logbook['pkl']?['dosen'] ?? {};
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
              // IDENTITAS MAHASISWA
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF145C4B),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mahasiswa['name'] ?? 'Mahasiswa',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Dosen: ${dosen['name'] ?? '-'}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // DETAIL LOGBOOK
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
                          fontSize: 16,
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
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            alignment: Alignment.center,
                            color: Colors.grey.shade200,
                            child: const Text(
                              'Foto tidak dapat dimuat',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (hasGps) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Lokasi GPS',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lat: $latitude',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Lng: $longitude',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _bukaMaps(
                                double.parse(latitude.toString()),
                                double.parse(longitude.toString()),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Peta'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.location_off,
                                color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tidak ada lokasi GPS.',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // CATATAN DOSEN
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

              // RIWAYAT REVIEW
              const SizedBox(height: 24),
              const Text(
                'Riwayat Review Dosen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF145C4B)),
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
                    'Belum ada riwayat review.',
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}