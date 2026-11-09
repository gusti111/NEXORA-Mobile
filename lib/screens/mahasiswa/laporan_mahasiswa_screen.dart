import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class LaporanMahasiswaScreen extends StatefulWidget {
  const LaporanMahasiswaScreen({super.key});

  @override
  State<LaporanMahasiswaScreen> createState() => _LaporanMahasiswaScreenState();
}

class _LaporanMahasiswaScreenState extends State<LaporanMahasiswaScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic> statistik = {
    'total_logbook': 0,
    'approved': 0,
    'pending': 0,
    'revision_requested': 0,
    'rejected': 0,
  };

  List<dynamic> logbooks = [];

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
      final results = await Future.wait([
        ApiService.getStudentStatistics(),
        ApiService.getStudentLogbooks(),
      ]);

      if (results[0]['success'] != true) {
        throw Exception(results[0]['message'] ?? 'Gagal ambil statistik');
      }
      if (results[1]['success'] != true) {
        throw Exception(results[1]['message'] ?? 'Gagal ambil logbook');
      }

      if (!mounted) return;
      setState(() {
        statistik = Map<String, dynamic>.from(results[0]['data'] ?? {});
        logbooks = results[1]['data'] ?? [];
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

  int get _hariPengisian {
    final set = <String>{};
    for (final l in logbooks) {
      final tgl = l['tanggal_kegiatan'];
      if (tgl != null) {
        try {
          final d = DateTime.parse(tgl.toString());
          set.add('${d.year}-${d.month}-${d.day}');
        } catch (_) {}
      }
    }
    return set.length;
  }

  Map<String, List<dynamic>> get _perBulan {
    final map = <String, List<dynamic>>{};
    const bulanNama = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    for (final l in logbooks) {
      try {
        final d = DateTime.parse(l['tanggal_kegiatan'].toString());
        final key = '${bulanNama[d.month - 1]} ${d.year}';
        map.putIfAbsent(key, () => []).add(l);
      } catch (_) {}
    }
    return map;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = _toInt(statistik['total_logbook']);
    final approved = _toInt(statistik['approved']);
    final pending = _toInt(statistik['pending']);
    final revision = _toInt(statistik['revision_requested']);
    final rejected = _toInt(statistik['rejected']);
    final persen = total == 0 ? 0.0 : approved / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Laporan Pribadi'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF176B4D)),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 50, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PROGRESS CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF145C4B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progres Pengumpulan',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$approved dari $total logbook disetujui',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: persen,
                                  minHeight: 10,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(persen * 100).toStringAsFixed(0)}% selesai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // STATISTIK
                        const Text(
                          'Rekap Logbook',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _infoCard(
                          'Total Logbook',
                          '$total',
                          Icons.book_outlined,
                          Colors.blue,
                        ),
                        _infoCard(
                          'Hari Pengisian',
                          '$_hariPengisian hari',
                          Icons.calendar_today,
                          Colors.teal,
                        ),
                        _infoCard(
                          'Disetujui',
                          '$approved',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                        _infoCard(
                          'Menunggu',
                          '$pending',
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                        _infoCard(
                          'Perlu Revisi',
                          '$revision',
                          Icons.edit_note,
                          Colors.orange.shade800,
                        ),
                        _infoCard(
                          'Ditolak',
                          '$rejected',
                          Icons.cancel_outlined,
                          Colors.red,
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Logbook per Bulan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_perBulan.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Belum ada logbook.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ..._perBulan.entries.map((entry) {
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
                                      color: const Color(0xFF176B4D)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xFF176B4D),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value.length} logbook',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
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

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}