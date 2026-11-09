import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class DetailMahasiswaKorlapScreen extends StatefulWidget {
  final Map<String, dynamic> pkl;
  const DetailMahasiswaKorlapScreen({super.key, required this.pkl});

  @override
  State<DetailMahasiswaKorlapScreen> createState() =>
      _DetailMahasiswaKorlapScreenState();
}

class _DetailMahasiswaKorlapScreenState
    extends State<DetailMahasiswaKorlapScreen> {
  bool _isSubmitting = false;

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

  Future<void> _selesaikanPkl() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selesaikan PKL?'),
        content: const Text(
          'Status PKL akan berubah menjadi "Selesai". '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Selesaikan',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final result = await ApiService.completeKorlapPkl(widget.pkl['id']);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PKL berhasil diselesaikan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyelesaikan PKL.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkl = widget.pkl;
    final mahasiswa = pkl['mahasiswa'] ?? {};
    final dosen = pkl['dosen'] ?? {};
    final verifikator = pkl['verifikator'];
    final status = pkl['status'] ?? '-';
    final isSelesai = status == 'selesai';
    final totalLogbook = pkl['logbooks_count'] ?? 0;
    final approved = pkl['logbooks_approved_count'] ?? 0;
    final progress = totalLogbook == 0 ? 0.0 : approved / totalLogbook;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detail Mahasiswa'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IDENTITAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF145C4B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (mahasiswa['name'] ?? 'M').toString().isNotEmpty
                          ? mahasiswa['name'].toString()[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mahasiswa['name'] ?? 'Mahasiswa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'NIM: ${mahasiswa['nim'] ?? '-'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mahasiswa['email'] ?? '-',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // STATUS BADGE
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isSelesai ? Colors.grey : Colors.blue)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSelesai ? 'PKL Selesai' : 'PKL Berlangsung',
                    style: TextStyle(
                      color: isSelesai ? Colors.grey : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // INFO PKL
            const Text(
              'Informasi PKL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoTile('Instansi', pkl['nama_instansi'] ?? '-',
                Icons.business_outlined),
            _infoTile('Alamat', pkl['alamat_instansi'] ?? '-',
                Icons.location_on_outlined),
            _infoTile('Dosen Pembimbing', dosen['name'] ?? '-',
                Icons.person_outline),
            _infoTile(
              'Periode',
              '${_formatTanggal(pkl['tanggal_mulai'])} - ${_formatTanggal(pkl['tanggal_selesai'])}',
              Icons.calendar_today_outlined,
            ),
            _infoTile(
              'Status',
              isSelesai ? 'Selesai' : 'Sedang Berlangsung',
              Icons.info_outline,
            ),

            const SizedBox(height: 20),

            // PROGRES LOGBOOK
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progres Logbook',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$approved dari $totalLogbook logbook disetujui',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        progress == 1.0 ? Colors.green : const Color(0xFF145C4B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% selesai',
                    style: const TextStyle(
                      color: Color(0xFF145C4B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // INFO VERIFIKATOR (kalau sudah selesai)
            if (isSelesai && verifikator != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PKL Telah Diverifikasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Oleh: ${verifikator['name'] ?? '-'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (pkl['tanggal_selesai_verifikasi'] != null)
                      Text(
                        'Tanggal: ${_formatTanggal(pkl['tanggal_selesai_verifikasi'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // TOMBOL SELESAIKAN PKL
            if (!isSelesai)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _selesaikanPkl,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Selesaikan PKL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF145C4B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF145C4B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}