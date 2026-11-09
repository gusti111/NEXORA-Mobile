import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FormPenggunaScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const FormPenggunaScreen({super.key, this.user});

  @override
  State<FormPenggunaScreen> createState() => _FormPenggunaScreenState();
}

class _FormPenggunaScreenState extends State<FormPenggunaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _role = 'mahasiswa';
  bool _isSubmitting = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _isEdit = true;
      _nameCtrl.text = widget.user!['name'] ?? '';
      _emailCtrl.text = widget.user!['email'] ?? '';
      _nimCtrl.text = widget.user!['nim'] ?? '';
      _usernameCtrl.text = widget.user!['username'] ?? '';
      _role = widget.user!['role'] ?? 'mahasiswa';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nimCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    Map<String, dynamic> result;

    if (_isEdit) {
      result = await ApiService.updateAdminUser(
        userId: widget.user!['id'],
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        nim: _nimCtrl.text.trim().isEmpty ? null : _nimCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        role: _role,
      );
    } else {
      result = await ApiService.createAdminUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
        nim: _nimCtrl.text.trim().isEmpty ? null : _nimCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Pengguna diperbarui.' : 'Pengguna dibuat.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleStatus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.user!['is_active'] == true ? 'Nonaktifkan akun?' : 'Aktifkan akun?'),
        content: const Text('Akun akan diubah statusnya. Pengguna akan diminta login ulang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.toggleAdminUserStatus(widget.user!['id']);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Status diubah.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal ubah status.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetPassword() async {
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password baru (min. 8 karakter)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    if (passCtrl.text.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter.'), backgroundColor: Colors.orange));
      return;
    }

    final result = await ApiService.resetAdminUserPassword(userId: widget.user!['id'], password: passCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Selesai.'), backgroundColor: result['success'] == true ? Colors.green : Colors.red));
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text('Akun "${widget.user!['name']}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.deleteAdminUser(widget.user!['id']);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Akun dihapus.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal hapus akun.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
        actions: [
          if (_isEdit)
            IconButton(onPressed: _deleteUser, icon: const Icon(Icons.delete_outline), tooltip: 'Hapus Akun'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Nama Lengkap'),
              TextFormField(controller: _nameCtrl, decoration: _dec('Masukkan nama'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null),
              const SizedBox(height: 16),

              _label('Email'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('contoh@email.com'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('Role'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _role,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                      DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                      DropdownMenuItem(value: 'korlap', child: Text('Korlap')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => v != null ? setState(() => _role = v) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_role == 'mahasiswa') ...[
                _label('NIM'),
                TextFormField(controller: _nimCtrl, decoration: _dec('NIM mahasiswa')),
                const SizedBox(height: 16),
              ],

              _label('Username (opsional)'),
              TextFormField(controller: _usernameCtrl, decoration: _dec('Username unik')),
              const SizedBox(height: 16),

              if (!_isEdit) ...[
                _label('Password'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: _dec('Min. 8 karakter'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145C4B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Buat Pengguna', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),

              if (_isEdit) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Aksi Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: const Color(0xFF145C4B)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _toggleStatus,
                  icon: Icon(widget.user!['is_active'] == true ? Icons.block : Icons.check_circle),
                  label: Text(widget.user!['is_active'] == true ? 'Nonaktifkan Akun' : 'Aktifkan Akun'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), foregroundColor: widget.user!['is_active'] == true ? Colors.orange : Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}