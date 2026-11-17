import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../models/event_registration_model.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/qr_kehadiran_card.dart';

/// Tab Tampilan Balapan Saya & Kartu Paddock Pass (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Tiket pendaftaran balap rider
/// - Status verifikasi bayar: PENDING, REJECTED (bisa upload ulang), PAID (Nomor Balap & QR)
/// - Status Kehadiran & Scrutineering
/// - Event yang sedang live di sirkuit (ONGOING)
class RiderActiveRaceView extends StatefulWidget {
  final VoidCallback onOpenLeaderboard;

  const RiderActiveRaceView({
    super.key,
    required this.onOpenLeaderboard,
  });

  @override
  State<RiderActiveRaceView> createState() => _RiderActiveRaceViewState();
}

class _RiderActiveRaceViewState extends State<RiderActiveRaceView> {
  final RegistrationService _registrationService = RegistrationService();
  final EventService _eventService = EventService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LIVE EVENT ONGOING DI SIRKUIT HARI INI
        StreamBuilder<List<EventModel>>(
          stream: _eventService.getOngoingEventsStream(),
          builder: (context, snapshot) {
            final ongoingEvents = snapshot.data ?? [];
            if (ongoingEvents.isEmpty) {
              return const SizedBox.shrink();
            }

            final liveEvent = ongoingEvents.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildOngoingEventBanner(liveEvent),
            );
          },
        ),

        // 2. KARTU BALAP & PENDAFTARAN SAYA
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.confirmation_num_outlined, color: AppColors.primaryMaroon, size: 18),
                SizedBox(width: 8),
                Text(
                  'KARTU BALAP & TIKET SAYA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<List<EventRegistrationModel>>(
          stream: _registrationService.getMyRegistrationsStream(userId: _uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                ),
              );
            }

            final myRegistrations = snapshot.data ?? [];
            if (myRegistrations.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_motorsports_outlined, size: 44, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Belum Terdaftar di Balapan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pilih kejuaraan di tab MENDATANG untuk mendaftar dan mendapatkan nomor balap paddock resmi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: myRegistrations.map((reg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildRegistrationItem(reg),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRegistrationItem(EventRegistrationModel reg) {
    if (reg.paymentStatus == PaymentStatus.paid) {
      // Pembayaran Lunas -> Tampilkan Kartu Balap Resmi & QR Code
      return QrKehadiranCard(registration: reg);
    } else if (reg.paymentStatus == PaymentStatus.rejected) {
      // Pembayaran Ditolak -> Tampilkan Alasan & Tombol Unggah Ulang
      return _buildRejectedPaymentCard(reg);
    } else {
      // Pembayaran Masih PENDING Verifikasi Bendahara
      return _buildPendingPaymentCard(reg);
    }
  }

  Widget _buildPendingPaymentCard(EventRegistrationModel reg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, size: 12, color: Colors.amber.shade900),
                    const SizedBox(width: 4),
                    Text(
                      'MENUNGGU VERIFIKASI BENDAHARA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                reg.vehicleType,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reg.bikeName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Piston: ${reg.pistonDiameterMm.toStringAsFixed(1)}mm • Rider: ${reg.riderName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          const Text(
            'Bukti transfer pendaftaran Anda sedang ditinjau oleh Bendahara (Dika). Nomor balap resmi dan QR Kehadiran akan diterbitkan secara otomatis setelah status pembayaran disetujui.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedPaymentCard(EventRegistrationModel reg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 12, color: Colors.red.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'BUKTI TRANSFER DITOLAK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                reg.vehicleType,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reg.bikeName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Alasan Penolakan: ${reg.paymentRejectionReason ?? "Struk bukti transfer tidak valid atau tidak terbaca"}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showReuploadDialog(reg),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
              label: const Text(
                'UNGGAH ULANG BUKTI BAYAR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReuploadDialog(EventRegistrationModel reg) {
    final controller = TextEditingController(text: reg.paymentProofUrl);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('UNGGAH ULANG BUKTI BAYAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan URL foto struk transfer baru untuk diverifikasi ulang oleh Bendahara:',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await _registrationService.reuploadPaymentProof(
                          registrationId: reg.registrationId,
                          newPaymentProofUrl: controller.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bukti transfer berhasil diperbarui! Menunggu verifikasi.'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('KIRIM ULANG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingEventBanner(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.imageUrl.isNotEmpty
                      ? event.imageUrl
                      : 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.sensors, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'RACE LIVE PADDOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.location} • Kelas ${event.className}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onOpenLeaderboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.leaderboard, size: 18, color: Colors.white),
                label: const Text(
                  'LIHAT PAPAN KLASEMEN / HASIL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

