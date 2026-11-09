import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'form_pkl_screen.dart';

class DaftarPklScreen extends StatefulWidget {
  const DaftarPklScreen({super.key});
  @override
  State<DaftarPklScreen> createState() => _DaftarPklScreenState();
}

class _DaftarPklScreenState extends State<DaftarPklScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> listPkl = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final result = await ApiService.getAdminPkls();
      if (result['success'] != true) throw Exception(result['message'] ?? 'Gagal memuat PKL.');
      if (!mounted) return;
      setState(() { listPkl = result['data'] ?? []; isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { errorMessage = e.toString().replaceFirst('Exception: ', ''); isLoading = false; });
    }
  }

  Future<void> _deletePkl(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus PKL?'),
        content: Text('Penempatan PKL "$nama" akan dihapus permanen. Pastikan tidak ada logbook terkait.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await ApiService.deleteAdminPkl(id);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PKL dihapus.'), backgroundColor: Colors.green));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal hapus PKL.'), backgroundColor: Colors.red));
    }
  }

  Color _statusColor(String s) => s == 'selesai' ? Colors.green : s == 'berlangsung' ? Colors.blue : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Manajemen PKL'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormPklScreen()));
          if (saved == true) _load();
        },
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
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
                      Center(child: ElevatedButton(onPressed: _load, child: const Text('Coba Lagi'))),
                    ],
                  )
                : listPkl.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Icon(Icons.business_center_outlined, size: 65, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Belum ada PKL.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: listPkl.length,
                        itemBuilder: (context, index) {
                          final pkl = Map<String, dynamic>.from(listPkl[index]);
                          return _buildPklCard(pkl);
                        },
                      ),
      ),
    );
  }

  Widget _buildPklCard(Map<String, dynamic> pkl) {
    final mahasiswa = pkl['mahasiswa'] ?? {};
    final dosen = pkl['dosen'] ?? {};
    final korlap = pkl['korlap'] ?? {};
    final status = pkl['status'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push(context, MaterialPageRoute(builder: (context) => FormPklScreen(pkl: pkl)));
          if (changed == true) _load();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(mahasiswa['name'] ?? 'Mahasiswa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(status == 'selesai' ? 'Selesai' : 'Berlangsung', style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(pkl['nama_instansi'] ?? '-', style: const TextStyle(color: Color(0xFF145C4B), fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [const Icon(Icons.person_outline, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text('Dosen: ${dosen['name'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)))]),
              Row(children: [const Icon(Icons.supervisor_account_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text('Korlap: ${korlap['name'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)))]),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text('${pkl['tanggal_mulai'] ?? '-'} s/d ${pkl['tanggal_selesai'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
                  IconButton(
                    onPressed: () => _deletePkl(pkl['id'], mahasiswa['name'] ?? 'PKL'),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Hapus PKL',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}