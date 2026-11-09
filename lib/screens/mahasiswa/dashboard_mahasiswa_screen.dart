import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'riwayat_logbook_screen.dart';
import 'buat_logbook_screen.dart';
import 'profil_mahasiswa_screen.dart';
import 'laporan_mahasiswa_screen.dart';

import '../../services/api_service.dart';
import '../../main.dart';
import '../notification_center_screen.dart';

class DashboardMahasiswaScreen extends StatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  State<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState extends State<DashboardMahasiswaScreen> {
  bool isLoading = true;
  String? errorMessage;

  String namaMahasiswa = 'Mahasiswa';
  Map<String, dynamic>? pkl;
  Map<String, dynamic> statistik = {
    'total_logbook': 0,
    'approved': 0,
    'pending': 0,
    'revision_requested': 0,
    'rejected': 0,
  };

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
        namaMahasiswa = user['name'] ?? 'Mahasiswa';
      }

      final results = await Future.wait([
        ApiService.getStudentPkls(),
        ApiService.getStudentStatistics(),
      ]);

      final pklResult = results[0];
      final statistikResult = results[1];

      if (pklResult['success'] != true) {
        throw Exception(pklResult['message'] ?? 'Gagal mengambil data PKL.');
      }

      if (statistikResult['success'] != true) {
        throw Exception(
          statistikResult['message'] ?? 'Gagal mengambil statistik.',
        );
      }

      final List<dynamic> daftarPkl = pklResult['data'] ?? [];
      final List<dynamic> daftarAktif = daftarPkl
          .where((item) =>
              item['status'] == 'berlangsung' || item['status'] == 'selesai')
          .toList();

      if (!mounted) return;

      setState(() {
        pkl = daftarAktif.isNotEmpty
            ? Map<String, dynamic>.from(daftarAktif.first)
            : null;

        statistik = Map<String, dynamic>.from(statistikResult['data'] ?? {});
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

  String formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';
    try {
      final date = DateTime.parse(tanggal.toString());
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return '-';
    }
  }

  double get _progress {
    if (pkl == null) return 0.0;
    try {
      final mulai = DateTime.parse(pkl!['tanggal_mulai'].toString());
      final selesai = DateTime.parse(pkl!['tanggal_selesai'].toString());
      final now = DateTime.now();

      if (now.isBefore(mulai)) return 0.0;
      if (now.isAfter(selesai)) return 1.0;

      final total = selesai.difference(mulai).inDays;
      final lewat = now.difference(mulai).inDays;

      if (total <= 0) return 0.0;
      return (lewat / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  int get _sisaHari {
    if (pkl == null) return 0;
    try {
      final selesai = DateTime.parse(pkl!['tanggal_selesai'].toString());
      final now = DateTime.now();
      final sisa = selesai.difference(now).inDays;
      return sisa > 0 ? sisa : 0;
    } catch (_) {
      return 0;
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
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
            },
          ),
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
                  'NEXORA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176B4D),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Halo, $namaMahasiswa! 👋',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pusat aktivitas dan pencatatan kegiatan PKL kamu.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 25),

                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: Color(0xFF176B4D)),
                    ),
                  )
                else if (errorMessage != null)
                  _ErrorCard(message: errorMessage!, onRetry: loadDashboard)
                else if (pkl == null)
                  _buildNoPklCard()
                else ...[
                  _buildPklCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Ringkasan Logbook',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: statistik['total_logbook'] ?? 0,
                          icon: Icons.book_outlined,
                          color: Colors.blue,
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
                          title: 'Menunggu',
                          value: statistik['pending'] ?? 0,
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Revisi',
                          value: statistik['revision_requested'] ?? 0,
                          icon: Icons.edit_note,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 28),

                const Text(
                  'Menu Utama',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _MenuCard(
                  icon: Icons.add_circle_outline,
                  title: 'Buat Logbook',
                  subtitle: 'Catat kegiatan PKL harian kamu',
                  onTap: () async {
                    final berhasil = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuatLogbookScreen(),
                      ),
                    );
                    if (berhasil == true) loadDashboard();
                  },
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.history,
                  title: 'Riwayat Logbook',
                  subtitle: 'Lihat seluruh catatan kegiatan PKL',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiwayatLogbookScreen(),
                      ),
                    );
                    if (mounted) loadDashboard();
                  },
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.insert_chart_outlined,
                  title: 'Laporan Pribadi',
                  subtitle: 'Rekap kegiatan & progres pengumpulan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaporanMahasiswaScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.person_outline,
                  title: 'Profil Saya',
                  subtitle: 'Lihat informasi akun mahasiswa',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilMahasiswaScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPklCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, size: 50, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum Ada Penempatan PKL',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Hubungi Admin atau Korlap untuk info penempatan PKL.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPklCard() {
    final dosen = pkl!['dosen']?['name'] ?? '-';
    final korlap = pkl!['korlap']?['name'] ?? '-';
    final alamat = pkl!['alamat_instansi'] ?? 'Alamat belum diisi';
    final statusPkl = pkl!['status'] ?? 'berlangsung';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF176B4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATUS PKL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusPkl == 'selesai' ? 'Selesai' : 'Aktif',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pkl!['nama_instansi'] ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alamat,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text(
            'Progres PKL',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progress * 100).toStringAsFixed(0)}% selesai',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                statusPkl == 'selesai'
                    ? 'PKL telah berakhir'
                    : 'Sisa $_sisaHari hari',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoPkl('Dosen Pembimbing', Icons.person, dosen)),
              const SizedBox(width: 12),
              Expanded(
                child: _infoPkl('Korlap', Icons.supervisor_account, korlap),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatTanggal(pkl!['tanggal_mulai'])} - ${formatTanggal(pkl!['tanggal_selesai'])}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPkl(String label, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
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
                color: const Color(0xFF176B4D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF176B4D)),
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