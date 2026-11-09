import 'package:flutter/material.dart';

import 'services/api_service.dart';

import 'screens/mahasiswa/dashboard_mahasiswa_screen.dart';



void main() {
  runApp(const NexoraApp());
}



class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXORA Logbook PKL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145C4B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}



// ================= LOGIN SCREEN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.login(
      login: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final user = result['user'];

      if (user['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardAdminScreen(user: user),
          ),
        );
      } else if (user['role'] == 'mahasiswa') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardMahasiswaScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login berhasil. Role: ${user['role']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF145C4B),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFFFD54F),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Center(
                      child: Text(
                        'NEXORA',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: Color(0xFF145C4B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'LOGBOOK PRAKTIK KERJA LAPANGAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202B27),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan masuk untuk melanjutkan aktivitas PKL kamu.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Username atau Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan username atau email',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7E3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFF145C4B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username atau email wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E7E3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFF145C4B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 53,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF145C4B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF145C4B).withValues(alpha: 0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'NEXORA Logbook PKL',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Center(
                      child: Text(
                        'Politeknik Negeri Pontianak',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// ================= ADMIN DASHBOARD =================

class DashboardAdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardAdminScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  late Future<Map<String, dynamic>> _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = ApiService.getAdminStatistics();
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      _statistics = ApiService.getAdminStatistics();
    });

    await _statistics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
        title: const Text(
          'NEXORA Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF145C4B),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!['success'] != true) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 45),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.data?['message'] ??
                        'Gagal memuat dashboard.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshStatistics,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!['data'];

          return RefreshIndicator(
            color: const Color(0xFF145C4B),
            onRefresh: _refreshStatistics,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202B27),
                  ),
                ),
                Text(
                  'Selamat datang, ${widget.user['name'] ?? widget.user['username'] ?? 'Admin'}!',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Ringkasan Sistem',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _StatCard(
                      title: 'Total Pengguna',
                      value: stats['total_pengguna'],
                      icon: Icons.people_alt_outlined,
                    ),
                    _StatCard(
                      title: 'Mahasiswa',
                      value: stats['total_mahasiswa'],
                      icon: Icons.school_outlined,
                    ),
                    _StatCard(
                      title: 'Dosen',
                      value: stats['total_dosen'],
                      icon: Icons.person_outline,
                    ),
                    _StatCard(
                      title: 'Korlap',
                      value: stats['total_korlap'],
                      icon: Icons.supervisor_account_outlined,
                    ),
                    _StatCard(
                      title: 'Total PKL',
                      value: stats['total_pkl'],
                      icon: Icons.business_outlined,
                    ),
                    _StatCard(
                      title: 'Total Logbook',
                      value: stats['total_logbook'],
                      icon: Icons.menu_book_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  'Status Logbook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _StatusCard(
                  title: 'Menunggu Persetujuan',
                  value: stats['pending'],
                  color: Colors.orange,
                  icon: Icons.hourglass_empty,
                ),
                _StatusCard(
                  title: 'Disetujui',
                  value: stats['approved'],
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
                _StatusCard(
                  title: 'Perlu Revisi',
                  value: stats['revision_requested'],
                  color: Colors.blue,
                  icon: Icons.edit_note,
                ),
                _StatusCard(
                  title: 'Ditolak',
                  value: stats['rejected'],
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'NEXORA Logbook PKL • POLNEP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



// ================= STATISTIC CARD =================

class _StatCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: const Color(0xFF145C4B),
            size: 27,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF145C4B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}



// ================= STATUS CARD =================

class _StatusCard extends StatelessWidget {
  final String title;
  final dynamic value;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
