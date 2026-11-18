import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordHidden = true;
  bool rememberMe = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fungsi Autentikasi Firebase + Cek Role Firestore (ERD v1.3.1)
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Harap isi Identitas Akses dan Kunci Telemetri', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Masuk dengan Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      String fullName = 'Pembalap';
      String role = 'anggota';

      // 2. Pastikan dokumen profil di koleksi 'users' tersedia sesuai ERD v1.3.1
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        fullName = (data['fullName'] ?? 'Pembalap').toString();
        role = (data['role'] ?? 'anggota').toString().toLowerCase();
      } else {
        // Fallback jika akun dibuat manual lewat Firebase Auth Console
        await userRef.set({
          'uid': uid,
          'email': email,
          'fullName': userCredential.user?.displayName ?? 'Anggota Paddock',
          'phoneNumber': '',
          'role': 'anggota',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _showMessage('Selamat datang, $fullName (${role.toUpperCase()})');

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan autentikasi.';

      if (e.code == 'user-not-found') {
        errorMessage = 'Pembalap dengan email ini tidak ditemukan di Paddock.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kunci Telemetri salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format Identitas Akses (Email) tidak valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun ini telah dinonaktifkan oleh ofisial.';
      } else if (e.code == 'invalid-credential' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        errorMessage = 'Email atau Kunci Telemetri tidak cocok.';
      }

      _showMessage(errorMessage, isError: true);
    } catch (e) {
      _showMessage('Terjadi kesalahan jaringan atau server: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi Reset Sandi via Email Firebase Auth
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Masukkan Identitas Akses (Email) Anda terlebih dahulu untuk reset sandi.', isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Tautan reset sandi telah dikirim ke $email');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        _showMessage('Format email tidak valid.', isError: true);
      } else {
        _showMessage('Gagal mengirim email reset sandi: ${e.message}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.toggleBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.two_wheeler, size: 30, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'DRAG HUB',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1.0),
              ),
              const SizedBox(height: 4),
              const Text(
                'RACER & OFFICIAL PORTAL',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSubtitle, letterSpacing: 2.0),
              ),
              const SizedBox(height: 48),

              _buildInputLabel('IDENTITAS AKSES'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hintText: 'driver@draghub.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('KUNCI TELEMETRI'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••••••',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: (val) => setState(() => rememberMe = val ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Ingat saya', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _handleForgotPassword,
                    child: const Text('Lupa sandi?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('MASUK PADDOCK', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ATAU', style: TextStyle(color: AppColors.textSubtitle.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                ],
              ),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.toggleBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TIMING ENGINE 2.4 GHZ READY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSubtitle, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Daftar Paddock', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: AppColors.textSubtitle, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }

  Widget _buildTextField({required String hintText, required IconData prefixIcon, bool isPassword = false, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && isPasswordHidden,
        keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isPassword ? AppColors.textSubtitle : AppColors.primary.withOpacity(0.4)),
          prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}