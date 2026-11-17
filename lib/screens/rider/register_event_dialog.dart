import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../models/motorcycle_model.dart';
import '../../services/motorcycle_service.dart';
import '../../services/registration_service.dart';
import '../../theme/app_colors.dart';
import '../add_bike_screen.dart';

/// Modal Dialog Pendaftaran Event Balap Resmi (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4:
/// - Memfilter motor: hanya motor yang transmisi cocok & piston <= batas event
/// - Cek kuota: tidak bisa daftar jika sisa kuota 0
/// - Unggah URL bukti transfer struk bank
class RegisterEventDialog extends StatefulWidget {
  final EventModel event;

  const RegisterEventDialog({
    super.key,
    required this.event,
  });

  @override
  State<RegisterEventDialog> createState() => _RegisterEventDialogState();
}

class _RegisterEventDialogState extends State<RegisterEventDialog> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final MotorcycleService _motorcycleService = MotorcycleService();
  final RegistrationService _registrationService = RegistrationService();

  MotorcycleModel? _selectedBike;
  final TextEditingController _riderNameCtrl = TextEditingController();
  final TextEditingController _proofUrlCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _riderNameCtrl.text = user?.displayName ?? '';
    // Isi default placeholder gambar bukti transfer agar mudah ditest
    _proofUrlCtrl.text = 'https://placehold.co/600x400/png?text=Bukti+Transfer+Lunas';
  }

  @override
  void dispose() {
    _riderNameCtrl.dispose();
    _proofUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_selectedBike == null) {
      _showSnackbar('Silakan pilih motor balap yang akan digunakan.', isError: true);
      return;
    }

    if (_riderNameCtrl.text.trim().isEmpty) {
      _showSnackbar('Nama pembalap tidak boleh kosong.', isError: true);
      return;
    }

    if (_proofUrlCtrl.text.trim().isEmpty) {
      _showSnackbar('Mohon sertakan tautan bukti transfer pembayaran.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _registrationService.registerForEvent(
        event: widget.event,
        bike: _selectedBike!,
        paymentProofUrl: _proofUrlCtrl.text.trim(),
        riderName: _riderNameCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil dikirim! Menunggu verifikasi Bendahara.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Gagal mendaftar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
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
    final event = widget.event;
    final targetVehicleType = VehicleType.fromValue(event.vehicleType.toUpperCase());

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FORMULIR PENDAFTARAN BALAP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMaroon,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
                  ),
                  child: Text(
                    'SISA: ${event.remainingQuota}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kelas: ${event.className} (Maks. Piston: ${event.maxPistonDiameterMm.toStringAsFixed(0)}mm)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // STREAM MOTOR SAYA (DIFILTER SESUAI REGULASI KELAS)
            const Text(
              'PILIH MOTOR BALAP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<MotorcycleModel>>(
              stream: _motorcycleService.getMyMotorcyclesStream(userId: _uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                  ));
                }

                final allBikes = snapshot.data ?? [];
                if (allBikes.isEmpty) {
                  return _buildNoBikePrompt(
                    'Anda belum memiliki motor balap di garasi.',
                  );
                }

                // Filter motor yang memenuhi syarat kelas event
                final eligibleBikes = allBikes.where((bike) {
                  return bike.isEligibleFor(
                    eventVehicleType: targetVehicleType,
                    maxPistonDiameterMm: event.maxPistonDiameterMm,
                  );
                }).toList();

                if (eligibleBikes.isEmpty) {
                  return _buildNoBikePrompt(
                    'Tidak ada motor Anda yang memenuhi regulasi event ini '
                    '(${event.vehicleType} & Piston <= ${event.maxPistonDiameterMm.toStringAsFixed(0)}mm).',
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.segmentBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MotorcycleModel>(
                      value: _selectedBike != null && eligibleBikes.any((b) => b.bikeId == _selectedBike!.bikeId)
                          ? eligibleBikes.firstWhere((b) => b.bikeId == _selectedBike!.bikeId)
                          : eligibleBikes.first,
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() => _selectedBike = val);
                      },
                      items: eligibleBikes.map((bike) {
                        return DropdownMenuItem<MotorcycleModel>(
                          value: bike,
                          child: Text(
                            '${bike.brand} ${bike.modelName} (Piston ${bike.pistonDiameterMm}mm • ${bike.vehicleType.value})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            _buildInputField('NAMA PEMBALAP', 'Nama di kartu start balap', _riderNameCtrl),
            const SizedBox(height: 12),
            _buildInputField(
              'BUKTI TRANSFER BIAYA PENDAFTARAN',
              'Tautan URL bukti pembayaran struk bank',
              _proofUrlCtrl,
              helperText: 'Biaya pendaftaran: Rp ${event.registrationFee}',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || event.remainingQuota <= 0 ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        event.remainingQuota <= 0 ? 'KUOTA HABIS' : 'KIRIM PENDAFTARAN',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBikePrompt(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 11, color: Colors.red.shade900, height: 1.4),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBikeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text(
              'Tambah Motor Sekarang',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              isDense: true,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText, style: const TextStyle(fontSize: 10, color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}

