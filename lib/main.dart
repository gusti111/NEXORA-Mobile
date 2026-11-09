import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'services/session_token_store.dart';
import 'screens/mahasiswa/dashboard_mahasiswa_screen.dart';
import 'screens/dosen/dashboard_dosen_screen.dart';
import 'screens/korlap/dashboard_korlap_screen.dart';
import 'screens/admin/dashboard_admin_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const NexoraApp());
}

class NexoraApp extends StatefulWidget {
  const NexoraApp({super.key});

  @override
  State<NexoraApp> createState() => _NexoraAppState();
}

class _NexoraAppState extends State<NexoraApp> with WidgetsBindingObserver {
  static const Duration sessionTimeout = Duration(minutes: 5);

  bool _checkingSession = false;
  bool _redirectingAfterUnauthorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiService.onUnauthorized = _handleUnauthorized;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (ApiService.onUnauthorized == _handleUnauthorized) {
      ApiService.onUnauthorized = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _saveBackgroundTime();
    }

    if (state == AppLifecycleState.resumed) {
      _checkSessionTimeout();
    }
  }

  Future<void> _saveBackgroundTime() async {
    final token = await SessionTokenStore.readToken();
    if (token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'background_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _checkSessionTimeout() async {
    if (_checkingSession) return;

    _checkingSession = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = await SessionTokenStore.readToken();
      final backgroundAt = prefs.getInt('background_at');

      if (token == null || token.isEmpty || backgroundAt == null) {
        return;
      }

      final elapsed =
          DateTime.now().millisecondsSinceEpoch - backgroundAt;

      if (elapsed >= sessionTimeout.inMilliseconds) {
        await ApiService.logout();

        if (!mounted) return;

        final navigator = navigatorKey.currentState;
        if (navigator == null) return;

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          final dialogContext = navigatorKey.currentContext;

          if (dialogContext == null || !dialogContext.mounted) return;

          showDialog(
            context: dialogContext,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sesi Berakhir'),
              content: const Text(
                'Sesi login Anda telah berakhir. '
                'Silakan login kembali.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      } else {
        await prefs.remove('background_at');
        await ApiService.validateSession();
      }
    } finally {
      _checkingSession = false;
    }
  }

  Future<void> _handleUnauthorized() async {
    if (!mounted || _redirectingAfterUnauthorized) return;
    _redirectingAfterUnauthorized = true;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _redirectingAfterUnauthorized = false;
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'NEXORA Logbook PKL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145C4B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _checkLogin();
  }

  Future<Widget> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final token = await SessionTokenStore.readToken();
    final userString = prefs.getString('user');
    final backgroundAt = prefs.getInt('background_at');

    if (token == null || token.isEmpty || userString == null) {
      return const LoginScreen();
    }

    if (backgroundAt != null) {
      final elapsed =
          DateTime.now().millisecondsSinceEpoch - backgroundAt;

      if (elapsed >= const Duration(minutes: 5).inMilliseconds) {
        await ApiService.logout();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sesi Berakhir'),
              content: const Text(
                'Sesi login Anda telah berakhir. '
                'Silakan login kembali.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });

        return const LoginScreen();
      }

      await prefs.remove('background_at');
    }

    try {
      final cachedUser = jsonDecode(userString) as Map<String, dynamic>;
      final validation = await ApiService.validateSession();

      if (validation['statusCode'] == 401 || validation['statusCode'] == 403) {
        return const LoginScreen();
      }

      // When the device is offline, retain the cached profile and let the
      // dashboard display its normal connection error state.
      final user = validation['success'] == true
          ? Map<String, dynamic>.from(validation['user'] as Map)
          : cachedUser;

      if (user['role'] == 'admin') {
        return DashboardAdminScreen(user: user);
      }

      if (user['role'] == 'mahasiswa') {
        return const DashboardMahasiswaScreen();
      }

      if (user['role'] == 'dosen') {
        return const DashboardDosenScreen();
      }

      if (user['role'] == 'korlap') {
        return const DashboardKorlapScreen();
      }
    } catch (_) {
      await ApiService.logout();
    }

    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF145C4B),
              ),
            ),
          );
        }

        return snapshot.data ?? const LoginScreen();
      },
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
      } else if (user['role'] == 'dosen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardDosenScreen(),
          ),
        );
      } else if (user['role'] == 'korlap') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardKorlapScreen(),
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