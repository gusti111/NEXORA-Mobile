import 'package:flutter/material.dart';

class DetailMahasiswaDosenScreen extends StatelessWidget {
  final Map<String, dynamic> pkl;
  const DetailMahasiswaDosenScreen({super.key, required this.pkl});

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
    final mahasiswa = pkl['mahasiswa'] ?? {};
    final status = pkl['status'] ?? '-';

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
            const Text(
              'Informasi PKL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoTile('Instansi', pkl['nama_instansi'] ?? '-',
                Icons.business_outlined),
            _infoTile('Alamat', pkl['alamat_instansi'] ?? '-',
                Icons.location_on_outlined),
            _infoTile(
              'Periode',
              '${_formatTanggal(pkl['tanggal_mulai'])} - ${_formatTanggal(pkl['tanggal_selesai'])}',
              Icons.calendar_today_outlined,
            ),
            _infoTile(
              'Status',
              status == 'berlangsung'
                  ? 'Sedang Berlangsung'
                  : status == 'selesai'
                      ? 'Selesai'
                      : status,
              Icons.info_outline,
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