import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/motorcycle_service.dart';
import '../theme/app_colors.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isSaving = false;

  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _pistonCtrl = TextEditingController();

  String _brand = 'Honda';
  final List<String> _brandOptions = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Kawasaki',
    'Vespa',
  ];

  String _vehicleType = 'MATIC';

  @override
  void dispose() {
    _modelCtrl.dispose();
    _pistonCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBikeToGarage() async {
    if (currentUserId == null) return;
    if (_modelCtrl.text.trim().isEmpty || _pistonCtrl.text.trim().isEmpty) {
      _showMessage(
        'Mohon lengkapi Model dan Ukuran Piston motor Anda.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simpan ke root collection 'motorcycles' melalui MotorcycleService sesuai ERD v1.4
      await MotorcycleService().addMotorcycle(
        brand: _brand,
        modelName: _modelCtrl.text.trim(),
        vehicleType: _vehicleType,
        pistonDiameterMm:
            double.tryParse(_pistonCtrl.text.trim().replaceAll(',', '.')) ??
            0.0,
      );

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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TAMBAH MOTOR BALAP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              'MERK MOTOR',
              _brand,
              _brandOptions,
              (val) => setState(() => _brand = val!),
            ),
            _buildInputField(
              'MODEL KENDARAAN',
              'cth. Vario 125 / Aerox 155',
              _modelCtrl,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIPE TRANSMISI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToggle('MATIC', Icons.two_wheeler),
                      const SizedBox(width: 8),
                      _buildToggle('KOPLING', Icons.settings),
                    ],
                  ),
                ],
              ),
            ),

            _buildInputField(
              'DIAMETER PISTON AKTUAL (MM)',
              'cth. 62.5',
              _pistonCtrl,
              isNumber: true,
              suffix: 'MM',
            ),

            const SizedBox(height: 16),
            const Text(
              '* Motor hanya bisa didaftarkan ke event balap jika Tipe Transmisi cocok dan Piston tidak melebihi Batas Maksimal Event.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, IconData icon) {
    final isSelected = _vehicleType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryMaroon
                : AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryMaroon
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.segmentBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                onChanged: onChanged,
                items: options
                    .map<DropdownMenuItem<String>>(
                      (String val) => DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    String? suffix,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.segmentBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                suffixText: suffix,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'DAFTARKAN KE GARASI BALAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
