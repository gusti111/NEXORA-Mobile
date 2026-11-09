import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';

class DetailLogbookDosenScreen extends StatefulWidget {
  final Map<String, dynamic> logbook;
  const DetailLogbookDosenScreen({super.key, required this.logbook});

  @override
  State<DetailLogbookDosenScreen> createState() =>
      _DetailLogbookDosenScreenState();
}

class _DetailLogbookDosenScreenState extends State<DetailLogbookDosenScreen> {
  final _komentarController = TextEditingController();
  bool _isSubmitting = false;

  Map<String, dynamic>? history;
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result =
        await ApiService.getLogbookHistoryDosen(widget.logbook['id']);
    if (!mounted) return;
    setState(() {
      if (result['success'] == true) {
        history = Map<String, dynamic>.from(result['data'] ?? {});
      }
      isLoadingHistory = false;
    });
  }

  Future<void> _submitReview(String status) async {
    if (status != 'approved' && _komentarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar wajib diisi untuk revisi atau penolakan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ApiService.reviewDosenLogbook(
      logbookId: widget.logbook['id'],
      status: status,
      komentar: _komentarController.text.trim().isEmpty
          ? null
          : _komentarController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keputusan berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan keputusan.'),
          backgroundColor: Colors.red,
        ),
      );
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

  int get _jumlahRevisi {
    if (history == null) return 0;
    final list = history!['riwayat_pemeriksaan'] as List?;
    if (list == null) return 0;
    return list.where((e) => e['status'] == 'revision_requested').length;
  }

  @override
  Widget build(BuildContext context) {
    final logbook = widget.logbook;
    final status = logbook['status'] ?? 'pending';
    final isPending = status == 'pending';
    final foto = logbook['foto'];
    final latitude = logbook['latitude'];
    final longitude = logbook['longitude'];
    final hasGps = latitude != null && longitude != null;
    final mahasiswa = logbook['pkl']?['mahasiswa'] ?? {};
    final namaMahasiswa = mahasiswa['name'] ?? 'Mahasiswa';
    final nimMahasiswa = mahasiswa['nim'] ?? '-';
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
                            namaMahasiswa,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'NIM: $nimMahasiswa',
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
                      logbook['tanggal_kegiatan'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
                        'Lokasi Kegiatan',
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
                              label: const Text('Buka Peta'),
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
                              'Mahasiswa tidak melampirkan GPS.',
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
                            'Catatan Dosen Sebelumnya',
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
              Row(
                children: [
                  const Text(
                    'Riwayat Review',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (_jumlahRevisi > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Direvisi $_jumlahRevisi kali',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
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

              const SizedBox(height: 24),

              if (isPending) ...[
                const Text(
                  'Beri Keputusan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _komentarController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Tulis komentar (wajib untuk revisi/penolakan)...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitReview('approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Setujui'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitReview('revision_requested'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Minta Revisi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitReview('rejected'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tolak'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: _statusColor(status)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logbook ini sudah di-${_statusLabel(status).toLowerCase()}.',
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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