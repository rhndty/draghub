import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; // <-- Tanda // sudah dihapus agar halaman Home dikenali

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRacerTab = true; 
  bool isPasswordHidden = true;
  bool rememberMe = false;
  bool _isLoading = false; // State indikator proses login

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fungsi Autentikasi Firebase
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Harap isi Identitas Akses dan Kunci Telemetri', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mencoba masuk dengan Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showMessage('Berhasil masuk sebagai ${isRacerTab ? 'Pembalap' : 'Panitia'}');
      
      // Jeda 1 detik agar pesan sukses terbaca oleh pengguna
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigasi ke beranda jika login berhasil (Tanda // sudah dihapus)
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan autentikasi.';
      
      // Menerjemahkan kode error Firebase menjadi bahasa yang mudah dimengerti
      if (e.code == 'user-not-found') {
        errorMessage = 'Pembalap dengan email ini tidak ditemukan di Paddock.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kunci Telemetri salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format Identitas Akses (Email) tidak valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun ini telah dinonaktifkan oleh ofisial.';
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
         errorMessage = 'Email atau Kunci Telemetri tidak cocok.';
      }

      _showMessage(errorMessage, isError: true);
    } catch (e) {
      _showMessage('Terjadi kesalahan jaringan atau server.', isError: true);
    } finally {
      // Mematikan efek loading apapun hasil akhirnya
      if (mounted) {
        setState(() => _isLoading = false);
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
              const SizedBox(height: 40),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.toggleBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildRoleToggle(title: 'Pembalap', icon: Icons.sports_motorsports_outlined, isSelected: isRacerTab, onTap: () => setState(() => isRacerTab = true))),
                    Expanded(child: _buildRoleToggle(title: 'Panitia', icon: Icons.flag_outlined, isSelected: !isRacerTab, onTap: () => setState(() => isRacerTab = false))),
                  ],
                ),
              ),
              const SizedBox(height: 32),

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
                    onTap: () => _showMessage('Fitur reset sandi sedang dalam pengembangan.'), 
                    child: const Text('Lupa sandi?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol Login Diperbarui untuk mendukung state _isLoading
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
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
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.face, onTap: () {}),
                  const SizedBox(width: 16),
                  _buildSocialButton(Icons.g_mobiledata, iconSize: 32, onTap: () {}),
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
                    onTap: () {}, 
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

  Widget _buildRoleToggle({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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

  Widget _buildSocialButton(IconData icon, {double iconSize = 24, required VoidCallback onTap}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textSecondary, size: iconSize),
        onPressed: onTap,
      ),
    );
  }
}