import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/secure_logbook_image.dart';
import 'revisi_logbook_screen.dart';
import 'detail_logbook_mahasiswa_screen.dart';

class RiwayatLogbookScreen extends StatefulWidget {
  const RiwayatLogbookScreen({super.key});

  @override
  State<RiwayatLogbookScreen> createState() =>
      _RiwayatLogbookScreenState();
}

class _RiwayatLogbookScreenState extends State<RiwayatLogbookScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> logbooks = [];
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    loadLogbooks();
  }

  Future<void> loadLogbooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getStudentLogbooks();

      if (result['success'] != true) {
        throw Exception(
          result['message'] ?? 'Gagal mengambil riwayat logbook.',
        );
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

  String formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';

    try {
      final date = DateTime.parse(tanggal.toString());

      const bulan = [
        'Januari', 'Februari', 'Maret', 'April',
        'Mei', 'Juni', 'Juli', 'Agustus',
        'September', 'Oktober', 'November', 'Desember',
      ];

      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'revision_requested':
        return Colors.orange.shade800;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'pending':
        return 'Menunggu';
      case 'revision_requested':
        return 'Perlu Revisi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  List<dynamic> get _filteredLogbooks {
    if (_filter == 'semua') return logbooks;
    return logbooks.where((l) => l['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Logbook',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF176B4D),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadLogbooks,
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'semua', 'label': 'Semua'},
      {'key': 'pending', 'label': 'Menunggu'},
      {'key': 'approved', 'label': 'Disetujui'},
      {'key': 'revision_requested', 'label': 'Revisi'},
      {'key': 'rejected', 'label': 'Ditolak'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = _filter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f['label']!),
                selected: isActive,
                onSelected: (_) => setState(() => _filter = f['key']!),
                selectedColor: const Color(0xFF176B4D),
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF176B4D)),
      );
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off, size: 50, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Gagal Memuat Logbook',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: loadLogbooks,
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    final list = _filteredLogbooks;

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 130),
          Icon(Icons.menu_book_outlined, size: 65, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum Ada Logbook',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Catatan kegiatan PKL kamu akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = Map<String, dynamic>.from(list[index]);
        return _buildLogbookCard(item);
      },
    );
  }

  Widget _buildLogbookCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    final foto = item['foto'];
    final judul = item['judul_kegiatan'];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLogbookMahasiswaScreen(logbook: item),
          ),
        );
        if (changed == true && mounted) {
          loadLogbooks();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF176B4D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatTanggal(item['tanggal_kegiatan']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(status),
                    style: TextStyle(
                      color: statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (judul != null && judul.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                judul.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              item['deskripsi_kegiatan'] ?? '-',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (foto != null && foto.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SecureLogbookImage(
                  logbookId: int.parse(item['id'].toString()),
                  height: 160,
                  width: double.infinity,
                ),
              ),
            ],
            if (item['catatan_dosen'] != null &&
                item['catatan_dosen'].toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Dosen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['catatan_dosen'].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'revision_requested') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RevisiLogbookScreen(logbook: item),
                      ),
                    );
                    if (updated == true) loadLogbooks();
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Kirim Ulang Perbaikan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}