import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers untuk form
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _startNumberCtrl = TextEditingController();
  final TextEditingController _teamCtrl = TextEditingController();
  final TextEditingController _managerCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _bloodTypeCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _emergencyCtrl = TextEditingController();
  
  String _email = '';
  String _riderCategory = 'Pro Rider (A)';
  final List<String> _categoryOptions = ['Pro Rider (A)', 'Rookie (B)', 'Novice (C)', 'Exhibition'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- MENGAMBIL DATA DARI FIRESTORE ---
  Future<void> _loadUserData() async {
    if (currentUserId == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameCtrl.text = data['fullName'] ?? '';
          _nicknameCtrl.text = data['nickname'] ?? '';
          _phoneCtrl.text = data['phoneNumber'] ?? '';
          _email = data['email'] ?? '';
          _licenseCtrl.text = data['imiLicense'] ?? '';
          _startNumberCtrl.text = data['startNumber'] ?? '';
          _teamCtrl.text = data['teamName'] ?? '';
          _managerCtrl.text = data['managerName'] ?? '';
          _cityCtrl.text = data['city'] ?? '';
          _bloodTypeCtrl.text = data['bloodType'] ?? '';
          _weightCtrl.text = data['weight'] ?? '';
          _emergencyCtrl.text = data['emergencyContact'] ?? '';
          
          if (data['riderClass'] != null && _categoryOptions.contains(data['riderClass'])) {
            _riderCategory = data['riderClass'];
          }
        });
      }
    } catch (e) {
      _showMessage('Gagal memuat data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- MENYIMPAN DATA KE FIRESTORE ---
  Future<void> _saveProfile() async {
    if (currentUserId == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'fullName': _fullNameCtrl.text.trim(),
        'nickname': _nicknameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'imiLicense': _licenseCtrl.text.trim(),
        'startNumber': _startNumberCtrl.text.trim(),
        'teamName': _teamCtrl.text.trim(),
        'managerName': _managerCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'bloodType': _bloodTypeCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'emergencyContact': _emergencyCtrl.text.trim(),
        'riderClass': _riderCategory,
      });
      _showMessage('Profil berhasil diperbarui!');
      Navigator.pop(context); // Kembali ke halaman profil setelah simpan
    } catch (e) {
      _showMessage('Gagal menyimpan profil: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _startNumberCtrl.dispose();
    _teamCtrl.dispose();
    _managerCtrl.dispose();
    _cityCtrl.dispose();
    _bloodTypeCtrl.dispose();
    _weightCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EDIT PROFILE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 1.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 32),
                  
                  // SECTION 1: IDENTITAS
                  _buildSectionTitle('IDENTITAS RESMI PEMBALAP'),
                  _buildInputField('NAMA LENGKAP', _fullNameCtrl, Icons.person_outline),
                  _buildInputField('NAMA PANGGILAN / RACING NICKNAME', _nicknameCtrl, Icons.badge_outlined),
                  _buildEmailField(),
                  _buildInputField('NOMOR WHATSAPP / PADDOCK CALL', _phoneCtrl, Icons.call_outlined, inputType: TextInputType.phone),
                  const SizedBox(height: 24),

                  // SECTION 2: LISENSI
                  _buildSectionTitle('LISENSI & FEDERASI (IMI)'),
                  _buildLicenseField(),
                  _buildCategoryAndStartNumber(),
                  const SizedBox(height: 24),

                  // SECTION 3: TIM BALAP
                  _buildSectionTitle('TIM BALAP & PADDOCK'),
                  _buildInputField('NAMA TIM BALAP', _teamCtrl, Icons.sports_motorsports_outlined),
                  _buildInputField('MANAJER / OFFICIAL PADDOCK', _managerCtrl, Icons.people_outline),
                  _buildInputField('KOTA ASAL / PENGPROV IMI', _cityCtrl, Icons.location_on_outlined),
                  const SizedBox(height: 24),

                  // SECTION 4: MEDIS
                  _buildSectionTitle('DATA MEDIS & DARURAT', trailingText: 'Safety Protocol', trailingIcon: Icons.local_hospital),
                  Row(
                    children: [
                      Expanded(child: _buildInputField('GOLONGAN DARAH', _bloodTypeCtrl, Icons.bloodtype_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField('BERAT PEMBALAP', _weightCtrl, Icons.scale_outlined, inputType: TextInputType.number)),
                    ],
                  ),
                  _buildInputField('KONTAK DARURAT (EMERGENCY)', _emergencyCtrl, Icons.contact_emergency_outlined),
                  const SizedBox(height: 32),

                  // TOMBOL SIMPAN & BATAL
                  _buildSaveButton(),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('BATALKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // --- WIDGET KOMPONEN UI ---

  Widget _buildPhotoSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: const Icon(Icons.person, size: 48, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_fullNameCtrl.text.isEmpty ? 'Pembalap' : _fullNameCtrl.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? trailingText, IconData? trailingIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 14, decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
            ],
          ),
          if (trailingText != null)
            Row(
              children: [
                if (trailingIcon != null) Icon(trailingIcon, size: 10, color: AppColors.primaryMaroon),
                const SizedBox(width: 4),
                Text(trailingText, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: controller,
              keyboardType: inputType,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EMAIL / AKUN PADDOCK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF004D40)),
                  SizedBox(width: 4),
                  Text('Terverifikasi', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: TextEditingController(text: _email),
              enabled: false,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.alternate_email, size: 18, color: AppColors.textMuted),
                suffixIcon: Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NOMOR LISENSI KTA IMI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFB2EBF2), borderRadius: BorderRadius.circular(4)),
                child: const Text('● VALID 2026', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF006064))),
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _licenseCtrl,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.verified_user_outlined, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndStartNumber() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KATEGORI PEMBALAP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _riderCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _riderCategory = newValue);
                    },
                    items: _categoryOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOMOR START', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: _startNumberCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '#...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('SIMPAN PERUBAHAN PROFIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}