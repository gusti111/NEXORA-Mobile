import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class RevisiLogbookScreen extends StatefulWidget {
  final Map<String, dynamic> logbook;

  const RevisiLogbookScreen({super.key, required this.logbook});

  @override
  State<RevisiLogbookScreen> createState() => _RevisiLogbookScreenState();
}

class _RevisiLogbookScreenState extends State<RevisiLogbookScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  File? _fotoBaru;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _judulController.text = widget.logbook['judul_kegiatan'] ?? '';
    _deskripsiController.text = widget.logbook['deskripsi_kegiatan'] ?? '';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _fotoBaru = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _kirimUlang() async {
    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ApiService.resubmitStudentLogbook(
      logbookId: widget.logbook['id'],
      judulKegiatan: _judulController.text.trim(),
      deskripsiKegiatan: _deskripsiController.text.trim(),
      foto: _fotoBaru,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logbook berhasil dikirim ulang.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim ulang.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Perbaiki Logbook'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.logbook['catatan_dosen'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Dosen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.logbook['catatan_dosen']),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text('Judul Kegiatan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Deskripsi Kegiatan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Foto Baru (Opsional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_fotoBaru != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _fotoBaru!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _fotoBaru = null),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pilihFoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pilihFoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _kirimUlang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF145C4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Ulang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}