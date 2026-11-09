import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'form_pengguna_screen.dart';

class DaftarPenggunaScreen extends StatefulWidget {
  const DaftarPenggunaScreen({super.key});

  @override
  State<DaftarPenggunaScreen> createState() => _DaftarPenggunaScreenState();
}

class _DaftarPenggunaScreenState extends State<DaftarPenggunaScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> users = [];
  String _filterRole = 'semua';
  String _search = '';

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
      final result = await ApiService.getAdminUsers();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Gagal memuat pengguna.');
      }
      if (!mounted) return;
      setState(() {
        users = result['data'] ?? [];
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

  List<dynamic> get _filteredUsers {
    var list = users;
    if (_filterRole != 'semua') {
      list = list.where((u) => u['role'] == _filterRole).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((u) {
        return (u['name'] ?? '').toString().toLowerCase().contains(q) ||
            (u['email'] ?? '').toString().toLowerCase().contains(q) ||
            (u['nim'] ?? '').toString().toLowerCase().contains(q) ||
            (u['username'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'dosen': return Colors.indigo;
      case 'korlap': return Colors.deepPurple;
      case 'mahasiswa': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormPenggunaScreen()),
          );
          if (saved == true) _load();
        },
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          // SEARCH & FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, NIM, atau username...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('semua', 'Semua'),
                      _chip('mahasiswa', 'Mahasiswa'),
                      _chip('dosen', 'Dosen'),
                      _chip('korlap', 'Korlap'),
                      _chip('admin', 'Admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF145C4B)))
                  : errorMessage != null
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 100),
                            const Icon(Icons.error_outline, size: 50, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                            ),
                          ],
                        )
                      : _filteredUsers.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 100),
                                Icon(Icons.people_outline, size: 65, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Tidak ada pengguna', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = Map<String, dynamic>.from(_filteredUsers[index]);
                                return _buildUserCard(user);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isActive = _filterRole == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => setState(() => _filterRole = key),
        selectedColor: const Color(0xFF145C4B),
        labelStyle: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? '-';
    final isActive = user['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormPenggunaScreen(user: user)),
          );
          if (changed == true) _load();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor(role),
                child: Text(
                  (user['name'] ?? 'U').toString().isNotEmpty ? user['name'].toString()[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(user['email'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    if (user['nim'] != null) Text('NIM: ${user['nim']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(role.toUpperCase(), style: TextStyle(color: _roleColor(role), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}