import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class BuatLogbookScreen extends StatefulWidget {
  const BuatLogbookScreen({super.key});

  @override
  State<BuatLogbookScreen> createState() => _BuatLogbookScreenState();
}

class _BuatLogbookScreenState extends State<BuatLogbookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  File? _fotoFile;
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  bool _isLoadingLocation = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (pickedFile != null) {
        setState(() => _fotoFile = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Layanan lokasi tidak aktif.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen.';
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil diambil!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _submitLogbook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final pklId = 1;
    final tanggalFormat =
        DateFormat('yyyy-MM-dd').format(_selectedDate);

    final result = await ApiService.createStudentLogbook(
      pklId: pklId,
      judulKegiatan: _judulController.text.trim(),
      tanggalKegiatan: tanggalFormat,
      deskripsiKegiatan: _deskripsiController.text,
      foto: _fotoFile,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logbook berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim logbook.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Buat Logbook'),
        backgroundColor: const Color(0xFF145C4B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tanggal Kegiatan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF176B4D)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Judul Kegiatan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Instalasi Jaringan Lab Komputer',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Deskripsi Kegiatan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Ceritakan kegiatan PKL kamu hari ini...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Foto Dokumentasi (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_fotoFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _fotoFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setState(() => _fotoFile = null),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              const Text('Lokasi (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _latitude != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}'
                            : 'Lokasi belum diambil',
                        style: TextStyle(
                          color: _latitude != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                    _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Ambil Lokasi'),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogbook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF145C4B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kirim Logbook',
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
      ),
    );
  }
}