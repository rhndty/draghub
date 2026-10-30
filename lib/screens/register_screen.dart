import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart'; // Pastikan path ini sesuai dengan project Anda

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Logika Backend Firebase
  Future<void> _registerUser() async {
    // 1. Validasi Input
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Semua kolom wajib diisi.');
      return;
    }

    if (!_agreeToTerms) {
      _showError('Anda harus menyetujui Regulasi Balap & Kebijakan Privasi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Buat Akun di Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Simpan Profil ke Firestore koleksi 'users'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'startNumber': '', // Akan diisi saat pendaftaran kelas
        'riderClass': 'NOVICE', // Default
        'role': 'PESERTA',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Sukses, pindah layar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Paddock berhasil dibuat!'), backgroundColor: Colors.green),
        );
        // Kembali ke halaman Login (atau langsung diarahkan ke Home jika diinginkan)
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        message = 'Kunci Telemetri (Password) terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar di Paddock.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      _showError(message);
    } catch (e) {
      _showError('Gagal mendaftar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Background off-white/light gray
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              
              // Form NAMA LENGKAP
              _buildInputLabel('NAMA LENGKAP'),
              _buildTextField(
                controller: _nameController,
                hintText: 'cth. Bayu Pratama',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Form EMAIL
              _buildInputLabel('IDENTITAS AKSES (EMAIL)'),
              _buildTextField(
                controller: _emailController,
                hintText: 'rider@apexdrag.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Form NOMOR TELEPON
              _buildInputLabel('NOMOR TELEPON / WHATSAPP'),
              _buildTextField(
                controller: _phoneController,
                hintText: '+62 812-xxxx-xxxx',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Form PASSWORD
              _buildInputLabel('KUNCI TELEMETRI (PASSWORD)'),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Checkbox Term & Conditions
              _buildTermsCheckbox(),
              const SizedBox(height: 24),

              // Tombol Submit
              _buildSubmitButton(),
              const SizedBox(height: 24),

              // Link ke Login
              _buildLoginLink(),
              const SizedBox(height: 40),

              // Badge Bawah
              _buildBottomBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Icon(Icons.speed, color: AppColors.primaryMaroon, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'DragHUB',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RACER & OFFICIAL REGISTRATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            activeColor: AppColors.primaryMaroon,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5),
                children: [
                  TextSpan(text: 'Saya menyetujui '),
                  TextSpan(text: 'Regulasi Balap', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                  TextSpan(text: ' & '),
                  TextSpan(text: 'Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                  TextSpan(text: ' Apex'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          disabledBackgroundColor: AppColors.primaryMaroon.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'BUAT AKUN PADDOCK',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // Kembali ke halaman Login
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          children: [
            TextSpan(text: 'Sudah punya akun? '),
            TextSpan(
              text: 'MASUK PADDOCK',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text(
            'TIMING ENGINE 2.4 GHZ READY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}