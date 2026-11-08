import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isSaving = false;
  bool _isAgreed = false;

  // Controllers
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _ccCtrl = TextEditingController();
  final TextEditingController _startNumberCtrl = TextEditingController();
  final TextEditingController _transponderCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _ecuCtrl = TextEditingController();
  final TextEditingController _mechanicCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  // Selections
  String _strokeConfig = '2T';
  String _targetClass = 'Bebek 2T 130cc Tune Up (DB2)';
  final List<String> _classOptions = [
    'Bebek 2T 130cc Tune Up (DB2)',
    'Bebek 4T TU 200cc',
    'Sport 2T 155cc Rangka Standar',
    'FFA 350cc'
  ];
  
  String _fuelType = 'Avgas 100LL';
  final List<String> _fuelOptions = ['Avgas 100LL', 'Pertamax Turbo', 'Bensol', 'VP Racing', 'Nitro/Methanol'];

  @override
  void dispose() {
    _modelCtrl.dispose();
    _nicknameCtrl.dispose();
    _ccCtrl.dispose();
    _startNumberCtrl.dispose();
    _transponderCtrl.dispose();
    _weightCtrl.dispose();
    _ecuCtrl.dispose();
    _mechanicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // --- FUNGSI SIMPAN KE FIRESTORE ---
  Future<void> _saveBikeToGarage() async {
    if (currentUserId == null) return;
    if (_modelCtrl.text.trim().isEmpty || _ccCtrl.text.trim().isEmpty || _startNumberCtrl.text.trim().isEmpty) {
      _showMessage('Mohon lengkapi Merek, CC, dan Nomor Start motor Anda.', isError: true);
      return;
    }
    if (!_isAgreed) {
      _showMessage('Anda harus menyetujui regulasi keselamatan.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Menyimpan data ke Subcollection 'garage' di dalam dokumen user saat ini
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('garage')
          .add({
        'modelBasis': _modelCtrl.text.trim(),
        'nickname': _nicknameCtrl.text.trim(),
        'capacityCc': int.tryParse(_ccCtrl.text.trim()) ?? 0,
        'strokeConfig': _strokeConfig,
        'targetClass': _targetClass,
        'startNumber': _startNumberCtrl.text.trim(),
        'transponder': _transponderCtrl.text.trim(),
        'weightKg': double.tryParse(_weightCtrl.text.trim()) ?? 0.0,
        'fuelType': _fuelType,
        'ecuManagement': _ecuCtrl.text.trim(),
        'mechanic': _mechanicCtrl.text.trim(),
        'tunerNotes': _notesCtrl.text.trim(),
        'status': 'MENUNGGU VERIFIKASI',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _showMessage('Motor berhasil didaftarkan ke garasi!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage('Gagal menyimpan motor: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'TAMBAH MOTOR BALAP',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGarageDocketHeader(),
            const SizedBox(height: 24),

            // SECTION 1: FOTO
            _buildSectionHeader('01. DOKUMENTASI VISUAL\nSCRUTINEERING', trailingBadge: 'WAJIB\nVERIFIKASI', isRedBadge: true),
            _buildPhotoUploader(),
            const SizedBox(height: 32),

            // SECTION 2: MESIN
            _buildSectionHeader('02. SPESIFIKASI TEKNIS MESIN', trailingText: 'POWERTRAIN DATA'),
            _buildInputField('MEREK & MODEL BASIS *', 'cth. Kawasaki Ninja 150 RR / Yamaha MX King', _modelCtrl),
            _buildInputField('NAMA PANGGILAN MOTOR / MACHINE NICKNAME', 'cth. Si Merah 201m / The Outlaw Ghost', _nicknameCtrl),
            _buildEngineSpecsRow(),
            _buildPresetChips(),
            const SizedBox(height: 32),

            // SECTION 3: KELAS & TELEMETRI
            _buildSectionHeader('03. KELAS BALAP & TELEMETRI', trailingText: 'RACE POD ASSIGNMENT'),
            _buildTargetClassDropdown(),
            _buildStartNumberRow(),
            _buildTransponderField(),
            const SizedBox(height: 32),

            // SECTION 4: BOBOT & ECU
            _buildSectionHeader('04. SETUP BOBOT & INSPEKSI\nTEKNIS', trailingText: 'SCALE\nCALIBRATION'),
            Row(
              children: [
                Expanded(child: _buildInputField('BOBOT KOSONG', '104.5', _weightCtrl, suffix: 'KG', inputType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildFuelDropdown()),
              ],
            ),
            _buildInputField('SISTEM PENGAPIAN & ECU MANAGEMENT', 'cth. aRacer SpeedTek Super X / KTC Racing', _ecuCtrl),
            const SizedBox(height: 32),

            // SECTION 5: CREW & NOTES
            _buildSectionHeader('05. PADDOCK CREW & TUNER NOTES', trailingText: 'CHIEF ENGINEER'),
            _buildInputField('KEPALA MEKANIK / ENGINE BUILDER', 'cth. Mas Budi - Jogja Dyno Tech', _mechanicCtrl, prefixIcon: Icons.build),
            _buildInputField('CATATAN KHUSUS PENYETELAN (GEAR RATIO / LAUNCH CONTROL)', 'Setup final gear 14-38 untuk lintasan aspal kering 201m. Shift-light setel di 13.000 RPM.', _notesCtrl, maxLines: 3),
            const SizedBox(height: 24),

            // FOOTER & ACTION
            _buildAgreementCheckbox(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATALKAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 24),
            _buildBottomTags(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- WIDGET KOMPONEN UI ---

  Widget _buildGarageDocketHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('GARAGE DOCKET: V3.9-ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 1.0)),
          ],
        ),
        Row(
          children: const [
            Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
            SizedBox(width: 4),
            Text('201M / 402M GRID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
          ],
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? trailingText, String? trailingBadge, bool isRedBadge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0, height: 1.4),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0),
            ),
          if (trailingBadge != null)
            Text(
              trailingBadge,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isRedBadge ? AppColors.primaryMaroon : AppColors.textMuted,
                letterSpacing: 1.0,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploader() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight, width: 2, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryMaroon, size: 24),
              ),
              const SizedBox(height: 12),
              const Text('UNGAH FOTO MOTOR BALAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              const Text('TAMPAK SAMPING / DYNO READY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Format JPG/PNG maks 10MB. Wajib memperlihatkan nomor start fisik, muffler knalpot, dan konfigurasi ground clearance untuk validasi tim inspeksi teknik.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.5),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {String? suffix, IconData? prefixIcon, int maxLines = 1, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: inputType,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.normal),
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: AppColors.textMuted) : null,
                suffixText: suffix,
                suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 16 : 14, horizontal: 16),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSpecsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: _buildInputField('KAPASITAS (CC) *', '155', _ccCtrl, suffix: 'CC', inputType: TextInputType.number),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STROKE CONFIG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStrokeToggle('2T'),
                    const SizedBox(width: 8),
                    _buildStrokeToggle('4T'),
                    const SizedBox(width: 8),
                    _buildStrokeToggle('EV'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrokeToggle(String label) {
    final isSelected = _strokeConfig == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _strokeConfig = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMaroon : AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primaryMaroon : AppColors.borderLight),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    final presets = ['130cc', '155cc', '200cc', '300cc FFA'];
    return Row(
      children: [
        const Text('PRESET:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _ccCtrl.text = e.replaceAll(RegExp(r'[^0-9]'), '')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  ),
                ),
              )).toList(),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTargetClassDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('KELAS BALAP TARGET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
              Text('IMI REGULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetClass,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _targetClass = newValue);
                },
                items: _classOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartNumberRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: _buildInputField('NOMOR START MOTOR *', '79', _startNumberCtrl, inputType: TextInputType.number),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('NOMOR DADA / PLAT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(4)),
                    alignment: Alignment.center,
                    child: Text(
                      _startNumberCtrl.text.isEmpty ? '#' : _startNumberCtrl.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransponderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.sensors, size: 12, color: AppColors.primaryMaroon),
                SizedBox(width: 4),
                Text('NOMOR SERIAL TRANSPONDER\nPADDOCK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5, height: 1.3)),
              ],
            ),
            const Text('CHRONO\nRX', textAlign: TextAlign.right, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0, height: 1.3)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: _transponderCtrl,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            decoration: const InputDecoration(
              hintText: 'APX-TX-99214-ID',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kosongkan bila menyewa transponder resmi panitia saat scrutineering di sirkuit.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.4),
        )
      ],
    );
  }

  Widget _buildFuelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BAHAN BAKAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fuelType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _fuelType = newValue);
                },
                items: _fuelOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isAgreed,
            activeColor: AppColors.primaryMaroon,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
            onChanged: (value) => setState(() => _isAgreed = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.5),
                children: [
                  TextSpan(text: 'Motor telah memenuhi regulasi keselamatan rangka, rem depan-belakang, dan engine cut-off switch sesuai panduan '),
                  TextSpan(text: 'Buku Tarung IMI Drag Bike 2026.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveBikeToGarage,
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
                  Text('DAFTARKAN KE GARASI BALAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomTags() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('SCRUTINEERING ENGINE INTEGRATED • APEX CHRONO READY', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('TIMING ACCURACY +0.0001 SEC • PADDOCK DOCK ID X8-ALPHA', style: TextStyle(fontSize: 6, color: AppColors.textMuted, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}