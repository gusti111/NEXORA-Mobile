import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../main.dart';

class ProfilMahasiswaScreen extends StatefulWidget {
  const ProfilMahasiswaScreen({super.key});

  @override
  State<ProfilMahasiswaScreen> createState() =>
      _ProfilMahasiswaScreenState();
}

class _ProfilMahasiswaScreenState extends State<ProfilMahasiswaScreen> {
  Map<String, dynamic> user = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null) {
      user = Map<String, dynamic>.from(jsonDecode(userData));
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
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
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
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

  Widget buildInfo(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF176B4D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF176B4D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF176B4D),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF176B4D)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF176B4D),
                    child: Text(
                      (user['name'] ?? 'M').toString().isNotEmpty
                          ? user['name'].toString()[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user['name'] ?? 'Mahasiswa',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Mahasiswa NEXORA',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Informasi Akun',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  buildInfo(
                    'Nama Lengkap',
                    user['name']?.toString() ?? '-',
                    Icons.person_outline,
                  ),
                  buildInfo(
                    'NIM',
                    user['nim']?.toString() ?? '-',
                    Icons.badge_outlined,
                  ),
                  buildInfo(
                    'Username',
                    user['username']?.toString() ?? '-',
                    Icons.alternate_email,
                  ),
                  buildInfo(
                    'Email',
                    user['email']?.toString() ?? '-',
                    Icons.email_outlined,
                  ),
                  buildInfo(
                    'Role',
                    user['role']?.toString().toUpperCase() ?? 'MAHASISWA',
                    Icons.verified_user_outlined,
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL LOGOUT
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
}