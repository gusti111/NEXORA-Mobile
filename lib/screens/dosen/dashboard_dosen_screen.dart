import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../main.dart';
import 'detail_logbook_dosen_screen.dart';
import 'daftar_mahasiswa_dosen_screen.dart';

class DashboardDosenScreen extends StatefulWidget {
  const DashboardDosenScreen({super.key});

  @override
  State<DashboardDosenScreen> createState() => _DashboardDosenScreenState();
}

class _DashboardDosenScreenState extends State<DashboardDosenScreen> {
  bool isLoading = true;
  String? errorMessage;
  String namaDosen = 'Dosen';

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
        namaDosen = user['name'] ?? 'Dosen';
      }

      final result = await ApiService.getDosenLogbooks();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Gagal mengambil data logbook.');
      }

      if (!mounted) return;
      setState(() {
        listLogbooks = result['data'] ?? [];
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

  int get _totalLogbook => listLogbooks.length;
  int get _pending =>
      listLogbooks.where((l) => l['status'] == 'pending').length;
  int get _approved =>
      listLogbooks.where((l) => l['status'] == 'approved').length;
  int get _revisi =>
      listLogbooks.where((l) => l['status'] == 'revision_requested').length;
  int get _rejected =>
      listLogbooks.where((l) => l['status'] == 'rejected').length;

  int get _totalMahasiswa {
    final set = <int>{};
    for (final l in listLogbooks) {
      final pkl = l['pkl'];
      if (pkl != null && pkl['mahasiswa_id'] != null) {
        set.add(pkl['mahasiswa_id']);
      }
    }
    return set.length;
  }

  List<dynamic> get _filteredLogbooks {
    if (_filter == 'semua') return listLogbooks;
    return listLogbooks.where((l) => l['status'] == _filter).toList();
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
                  'NEXORA DOSEN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF145C4B),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Halo, $namaDosen! 👋',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Panel pemantauan logbook mahasiswa bimbingan.',
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
                    'Ringkasan Bimbingan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Mahasiswa',
                          value: _totalMahasiswa,
                          icon: Icons.people_outline,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Logbook',
                          value: _totalLogbook,
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
                          value: _pending,
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Disetujui',
                          value: _approved,
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
                          value: _revisi,
                          icon: Icons.edit_note,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Ditolak',
                          value: _rejected,
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _MenuCard(
                    icon: Icons.list_alt,
                    title: 'Daftar Mahasiswa Bimbingan',
                    subtitle: 'Lihat semua mahasiswa & info PKL-nya',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DaftarMahasiswaDosenScreen(),
                        ),
                      );
                      if (mounted) loadDashboard();
                    },
                  ),

                  const SizedBox(height: 28),

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
    final namaMahasiswa = mahasiswa['name'] ?? 'Mahasiswa';
    final nim = mahasiswa['nim'] ?? '-';
    final judul = logbook['judul_kegiatan'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLogbookDosenScreen(
                logbook: Map<String, dynamic>.from(logbook),
              ),
            ),
          );
          if (changed == true) loadDashboard();
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
                      namaMahasiswa,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'NIM: $nim',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (judul != null && judul.toString().isNotEmpty)
                      Text(
                        judul.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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