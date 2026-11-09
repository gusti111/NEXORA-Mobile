import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FormPklScreen extends StatefulWidget {
  final Map<String, dynamic>? pkl;
  const FormPklScreen({super.key, this.pkl});
  @override
  State<FormPklScreen> createState() => _FormPklScreenState();
}

class _FormPklScreenState extends State<FormPklScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instansiCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();

  int? _mahasiswaId;
  int? _dosenId;
  int? _korlapId;
  String _tanggalMulai = '';
  String _tanggalSelesai = '';
  String _status = 'berlangsung';

  List<dynamic> _mahasiswaList = [];
  List<dynamic> _dosenList = [];
  List<dynamic> _korlapList = [];

  bool _isLoadingRef = true;
  bool _isSubmitting = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.pkl != null) {
      _isEdit = true;
      _instansiCtrl.text = widget.pkl!['nama_instansi'] ?? '';
      _alamatCtrl.text = widget.pkl!['alamat_instansi'] ?? '';
      _dosenId = widget.pkl!['dosen_id'];
      _korlapId = widget.pkl!['korlap_id'];
      _tanggalMulai = (widget.pkl!['tanggal_mulai'] ?? '').toString().split('T').first;
      _tanggalSelesai = (widget.pkl!['tanggal_selesai'] ?? '').toString().split('T').first;
      _status = widget.pkl!['status'] ?? 'berlangsung';
    }
    _loadRef();
  }

  Future<void> _loadRef() async {
    setState(() => _isLoadingRef = true);
    try {
      final result = await ApiService.getAdminUsers();
      if (result['success'] == true) {
        final list = result['data'] as List;
        if (!mounted) return;
        setState(() {
          _mahasiswaList = list.where((u) => u['role'] == 'mahasiswa').toList();
          _dosenList = list.where((u) => u['role'] == 'dosen').toList();
          _korlapList = list.where((u) => u['role'] == 'korlap').toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingRef = false);
  }

  @override
  void dispose() { _instansiCtrl.dispose(); _alamatCtrl.dispose(); super.dispose(); }

  Future<void> _pickTanggal(bool isMulai) async {
    final initial = (isMulai ? _tanggalMulai : _tanggalSelesai).isNotEmpty
        ? DateTime.tryParse(isMulai ? _tanggalMulai : _tanggalSelesai) : null;
    final picked = await showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked == null) return;
    final str = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() { if (isMulai) { _tanggalMulai = str; } else { _tanggalSelesai = str; } });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mahasiswaId == null && !_isEdit) { _snack('Pilih mahasiswa dulu.', Colors.orange); return; }
    if (_dosenId == null) { _snack('Pilih dosen dulu.', Colors.orange); return; }
    if (_korlapId == null) { _snack('Pilih korlap dulu.', Colors.orange); return; }
    if (_tanggalMulai.isEmpty) { _snack('Pilih tanggal mulai dulu.', Colors.orange); return; }

    setState(() => _isSubmitting = true);
    Map<String, dynamic> result;
    if (_isEdit) {
      result = await ApiService.updateAdminPkl(pklId: widget.pkl!['id'], dosenId: _dosenId!, korlapId: _korlapId!, namaInstansi: _instansiCtrl.text.trim(), alamatInstansi: _alamatCtrl.text.trim().isEmpty ? null : _alamatCtrl.text.trim(), tanggalMulai: _tanggalMulai, tanggalSelesai: _tanggalSelesai.isEmpty ? null : _tanggalSelesai, status: _status);
    } else {
      result = await ApiService.createAdminPkl(mahasiswaId: _mahasiswaId!, dosenId: _dosenId!, korlapId: _korlapId!, namaInstansi: _instansiCtrl.text.trim(), alamatInstansi: _alamatCtrl.text.trim().isEmpty ? null : _alamatCtrl.text.trim(), tanggalMulai: _tanggalMulai, tanggalSelesai: _tanggalSelesai.isEmpty ? null : _tanggalSelesai);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'PKL diperbarui.' : 'PKL dibuat.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      _snack(result['message'] ?? 'Gagal menyimpan.', Colors.red);
    }
  }

  void _snack(String msg, Color color) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text(_isEdit ? 'Edit PKL' : 'Tambah PKL'), backgroundColor: const Color(0xFF145C4B), foregroundColor: Colors.white),
      body: _isLoadingRef
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF145C4B)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isEdit) ...[
                      _label('Mahasiswa'),
                      _dropdownUser(list: _mahasiswaList, selected: _mahasiswaId, onChanged: (v) => setState(() => _mahasiswaId = v), hint: 'Pilih mahasiswa'),
                      const SizedBox(height: 16),
                    ],
                    _label('Dosen Pembimbing'),
                    _dropdownUser(list: _dosenList, selected: _dosenId, onChanged: (v) => setState(() => _dosenId = v), hint: 'Pilih dosen'),
                    const SizedBox(height: 16),
                    _label('Korlap'),
                    _dropdownUser(list: _korlapList, selected: _korlapId, onChanged: (v) => setState(() => _korlapId = v), hint: 'Pilih korlap'),
                    const SizedBox(height: 16),
                    _label('Nama Instansi'),
                    TextFormField(controller: _instansiCtrl, decoration: _dec('PT Contoh'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
                    const SizedBox(height: 16),
                    _label('Alamat Instansi'),
                    TextFormField(controller: _alamatCtrl, maxLines: 2, decoration: _dec('Alamat lengkap')),
                    const SizedBox(height: 16),
                    _label('Tanggal Mulai'),
                    _dateField(_tanggalMulai, () => _pickTanggal(true)),
                    const SizedBox(height: 16),
                    _label('Tanggal Selesai'),
                    _dateField(_tanggalSelesai, () => _pickTanggal(false)),
                    const SizedBox(height: 16),
                    if (_isEdit) ...[
                      _label('Status PKL'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'berlangsung', child: Text('Berlangsung')),
                              DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                            ],
                            onChanged: (v) => v != null ? setState(() => _status = v) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF145C4B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEdit ? 'Simpan Perubahan' : 'Buat PKL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));

  Widget _dropdownUser({required List<dynamic> list, required int? selected, required ValueChanged<int?> onChanged, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          isExpanded: true,
          hint: Text(hint),
          items: list.map((u) => DropdownMenuItem<int>(value: u['id'] as int, child: Text('${u['name']} (${u['email']})'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateField(String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF145C4B), size: 18),
            const SizedBox(width: 10),
            Text(value.isEmpty ? 'Pilih tanggal' : value, style: TextStyle(color: value.isEmpty ? Colors.grey : Colors.black87, fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14));
  }
}