import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'detail_mahasiswa_dosen_screen.dart';

class DaftarMahasiswaDosenScreen extends StatefulWidget {
  const DaftarMahasiswaDosenScreen({super.key});

  @override
  State<DaftarMahasiswaDosenScreen> createState() =>
      _DaftarMahasiswaDosenScreenState();
}

class _DaftarMahasiswaDosenScreenState
    extends State<DaftarMahasiswaDosenScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> listPkl = [];

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
      final result = await ApiService.getDosenMahasiswa();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Gagal ambil data mahasiswa');
      }
      if (!mounted) return;
      setState(() {
        listPkl = result['data'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mahasiswa Bimbingan'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF145C4B)),
              )
            : errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.cloud_off,
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
                : listPkl.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(Icons.school_outlined,
                              size: 65, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum Ada Mahasiswa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mahasiswa bimbingan akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: listPkl.length,
                        itemBuilder: (context, index) {
                          final pkl =
                              Map<String, dynamic>.from(listPkl[index]);
                          final mahasiswa = pkl['mahasiswa'] ?? {};
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailMahasiswaDosenScreen(pkl: pkl),
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
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          const Color(0xFF145C4B),
                                      child: Text(
                                        (mahasiswa['name'] ?? 'M')
                                            .toString()
                                            .isNotEmpty
                                            ? mahasiswa['name']
                                                .toString()[0]
                                                .toUpperCase()
                                            : 'M',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mahasiswa['name'] ?? 'Mahasiswa',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'NIM: ${mahasiswa['nim'] ?? '-'}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            pkl['nama_instansi'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF145C4B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}