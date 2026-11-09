import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../main.dart';
import 'daftar_pengguna_screen.dart';
import 'daftar_pkl_screen.dart';
import 'daftar_logbook_admin_screen.dart';
import 'pengaturan_screen.dart';

class DashboardAdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const DashboardAdminScreen({super.key, required this.user});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic> stats = {};

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
      final result = await ApiService.getAdminStatistics();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Gagal memuat statistik.');
      }
      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(result['data'] ?? {});
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

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
        title: const Text(
          'NEXORA Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF145C4B)),
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
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Halo, ${widget.user['name'] ?? widget.user['username'] ?? 'Admin'}! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Panel administrasi NEXORA.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Pengguna',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          _StatCard(
                            title: 'Total Pengguna',
                            value: _toInt(stats['total_pengguna']),
                            icon: Icons.people_alt,
                            color: Colors.blue,
                          ),
                          _StatCard(
                            title: 'Mahasiswa',
                            value: _toInt(stats['total_mahasiswa']),
                            icon: Icons.school,
                            color: Colors.teal,
                          ),
                          _StatCard(
                            title: 'Dosen',
                            value: _toInt(stats['total_dosen']),
                            icon: Icons.person,
                            color: Colors.indigo,
                          ),
                          _StatCard(
                            title: 'Korlap',
                            value: _toInt(stats['total_korlap']),
                            icon: Icons.supervisor_account,
                            color: Colors.deepPurple,
                          ),
                          _StatCard(
                            title: 'Aktif',
                            value: _toInt(stats['user_aktif']),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _StatCard(
                            title: 'Nonaktif',
                            value: _toInt(stats['user_nonaktif']),
                            icon: Icons.block,
                            color: Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'PKL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total PKL',
                              value: _toInt(stats['total_pkl']),
                              icon: Icons.business,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Berlangsung',
                              value: _toInt(stats['pkl_berlangsung']),
                              icon: Icons.play_circle,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Selesai',
                              value: _toInt(stats['pkl_selesai']),
                              icon: Icons.flag,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Logbook',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total',
                              value: _toInt(stats['total_logbook']),
                              icon: Icons.menu_book,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Pending',
                              value: _toInt(stats['pending']),
                              icon: Icons.hourglass_empty,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Approved',
                              value: _toInt(stats['approved']),
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Revisi',
                              value: _toInt(stats['revision_requested']),
                              icon: Icons.edit_note,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: 'Rejected',
                              value: _toInt(stats['rejected']),
                              icon: Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        'Menu Pengelolaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MenuCard(
                        icon: Icons.people_outline,
                        title: 'Manajemen Pengguna',
                        subtitle: 'Kelola akun mahasiswa, dosen, korlap, admin',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DaftarPenggunaScreen(),
                            ),
                          );
                          if (mounted) _load();
                        },
                      ),
                      const SizedBox(height: 10),
                      _MenuCard(
                        icon: Icons.business_center_outlined,
                        title: 'Manajemen PKL',
                        subtitle: 'Kelola penempatan PKL mahasiswa',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DaftarPklScreen(),
                            ),
                          );
                          if (mounted) _load();
                        },
                      ),
                      const SizedBox(height: 10),
                      _MenuCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Manajemen Logbook',
                        subtitle: 'Lihat semua logbook mahasiswa',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DaftarLogbookAdminScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _MenuCard(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan Sistem',
                        subtitle: 'Konfigurasi aplikasi NEXORA',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PengaturanScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
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