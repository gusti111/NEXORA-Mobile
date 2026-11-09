import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../main.dart';
import 'detail_logbook_korlap_screen.dart';
import 'daftar_mahasiswa_korlap_screen.dart';

class DashboardKorlapScreen extends StatefulWidget {
  const DashboardKorlapScreen({super.key});

  @override
  State<DashboardKorlapScreen> createState() => _DashboardKorlapScreenState();
}

class _DashboardKorlapScreenState extends State<DashboardKorlapScreen> {
  bool isLoading = true;
  String? errorMessage;
  String namaKorlap = 'Korlap';

  Map<String, dynamic> statistik = {
    'total_mahasiswa': 0,
    'total_logbook': 0,
    'pending': 0,
    'approved': 0,
    'revision_requested': 0,
    'rejected': 0,
  };

  List<dynamic> listLogbooks = [];
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      if (userData != null) {
        final user = jsonDecode(userData);
        namaKorlap = user['name'] ?? 'Korlap';
      }

      final results = await Future.wait([
        ApiService.getKorlapStatistics(),
        ApiService.getKorlapLogbooks(),
      ]);

      final statResult = results[0];
      final logbookResult = results[1];

      if (statResult['success'] != true) {
        throw Exception(statResult['message'] ?? 'Gagal ambil statistik.');
      }
      if (logbookResult['success'] != true) {
        throw Exception(
          logbookResult['message'] ?? 'Gagal ambil data logbook.',
        );
      }

      if (!mounted) return;
      setState(() {
        statistik = Map<String, dynamic>.from(statResult['data'] ?? {});
        listLogbooks = logbookResult['data'] ?? [];
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _exportFile(String type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF145C4B)),
            SizedBox(width: 20),
            Text('Mengunduh file...'),
          ],
        ),
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final result = await ApiService.downloadKorlapExport(
        type: type,
        savePath: directory.path,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Unduhan Berhasil'),
            content: Text(
              'File "${result['filename']}" berhasil diunduh.\n\nBuka sekarang?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Buka'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await OpenFilex.open(result['filePath']);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal mengunduh.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filteredLogbooks {
    if (_filter == 'semua') return listLogbooks;
    return listLogbooks.where((l) => l['status'] == _filter).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXORA KORLAP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF145C4B),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Halo, $namaKorlap! 👋',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Panel koordinasi PKL.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 25),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: Color(0xFF145C4B)),
                    ),
                  )
                else if (errorMessage != null)
                  _ErrorCard(message: errorMessage!, onRetry: loadDashboard)
                else ...[
                  const Text(
                    'Ringkasan Koordinasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Mahasiswa',
                          value: statistik['total_mahasiswa'] ?? 0,
                          icon: Icons.people_outline,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Logbook',
                          value: statistik['total_logbook'] ?? 0,
                          icon: Icons.menu_book_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Menunggu',
                          value: statistik['pending'] ?? 0,
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Disetujui',
                          value: statistik['approved'] ?? 0,
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Perlu Revisi',
                          value: statistik['revision_requested'] ?? 0,
                          icon: Icons.edit_note,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Ditolak',
                          value: statistik['rejected'] ?? 0,
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _MenuCard(
                    icon: Icons.list_alt,
                    title: 'Daftar Mahasiswa PKL',
                    subtitle: 'Monitoring mahasiswa & penyelesaian PKL',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DaftarMahasiswaKorlapScreen(),
                        ),
                      );
                      if (mounted) loadDashboard();
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Daftar Logbook Mahasiswa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(),
                  const SizedBox(height: 12),

                  if (_filteredLogbooks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada logbook dengan filter ini.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._filteredLogbooks.map((logbook) {
                      return _buildLogbookTile(logbook);
                    }),

                  const SizedBox(height: 24),

                  const Text(
                    'Unduh Laporan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportFile('excel'),
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportFile('pdf'),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
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

    return SingleChildScrollView(
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
              selectedColor: const Color(0xFF145C4B),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogbookTile(Map<String, dynamic> logbook) {
    final status = logbook['status'] ?? 'pending';
    final color = _statusColor(status);
    final mahasiswa = logbook['pkl']?['mahasiswa'] ?? {};
    final dosen = logbook['pkl']?['dosen'] ?? {};
    final judul = logbook['judul_kegiatan'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLogbookKorlapScreen(
                logbook: Map<String, dynamic>.from(logbook),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment, color: color),
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
                    if (judul != null && judul.toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        judul.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    Text(
                      logbook['tanggal_kegiatan'] ?? '-',
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF145C4B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF145C4B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 35, color: Colors.red),
          const SizedBox(height: 10),
          const Text(
            'Gagal Memuat Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}