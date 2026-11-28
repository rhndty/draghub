import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/event_model.dart';
import '../../models/event_registration_model.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/midtrans_payment_sheet.dart';
import '../../widgets/qr_kehadiran_card.dart';

/// Tab ONGOING / AKTIF (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Event yang sedang live berlangsung di sirkuit (status == 'ONGOING')
/// - Tiket Balap Rider & Paddock Pass:
///   * Status PAID: Nomor balap resmi #001 & QR kehadiran paddock (qr_kehadiran_card.dart)
///   * Status PENDING: Menunggu verifikasi pembayaran oleh Bendahara
///   * Status REJECTED: Tampilan alasan penolakan & fitur unggah ulang bukti transfer
class RiderOngoingView extends StatefulWidget {
  final VoidCallback onOpenPodium;

  const RiderOngoingView({super.key, required this.onOpenPodium});

  @override
  State<RiderOngoingView> createState() => _RiderOngoingViewState();
}

class _RiderOngoingViewState extends State<RiderOngoingView> {
  final EventService _eventService = EventService();
  final RegistrationService _registrationService = RegistrationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _isOpeningPayment = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LIVE EVENT SIRKUIT HARI INI (ONGOING)
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
              child: _buildOngoingLiveBanner(liveEvent),
            );
          },
        ),

        // 2. KARTU TIKET BALAP SAYA (PADDOCK PASS & NOMOR BALAP)
        Row(
          children: const [
            Icon(
              Icons.confirmation_num_outlined,
              color: AppColors.primaryMaroon,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'TIKET BALAP & PADDOCK PASS SAYA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 1.0,
              ),
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
                  child: CircularProgressIndicator(
                    color: AppColors.primaryMaroon,
                  ),
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
                    Icon(
                      Icons.sports_motorsports_outlined,
                      size: 44,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum Ada Tiket Balapan Aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Silakan buka tab UPCOMING untuk mendaftarkan motor balap Anda ke kejuaraan resmi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: myRegistrations.map((reg) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: _buildRegistrationCard(reg),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRegistrationCard(EventRegistrationModel reg) {
    if (reg.paymentStatus == PaymentStatus.paid) {
      // Pembayaran Lunas -> Tampilkan Kartu Balap Resmi & QR Code Kehadiran (PRD 4.4 & 4.5)
      return QrKehadiranCard(registration: reg);
    } else if (reg.paymentStatus == PaymentStatus.rejected) {
      // Pembayaran Ditolak -> Tampilkan Alasan & Tombol Unggah Ulang Bukti Bayar (PRD 4.3)
      return _buildRejectedPaymentCard(reg);
    } else {
      // Pembayaran Masih PENDING Verifikasi Bendahara
      return _buildPendingPaymentCard(reg);
    }
  }

  Future<void> _openMidtransPayment(EventRegistrationModel reg) async {
    if (_isOpeningPayment) return;
    setState(() => _isOpeningPayment = true);

    try {
      final event = await _eventService.getEventById(reg.eventId);
      if (!mounted) return;

      if (event == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data event tidak ditemukan. Hubungi panitia.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      int? assignedStartNumber;
      await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MidtransPaymentSheet(
          registrationId: reg.registrationId,
          eventId: reg.eventId,
          eventTitle: event.title,
          riderName: reg.riderName,
          amount: event.registrationFee,
          onPaymentSuccess: (startNumber) {
            assignedStartNumber = startNumber;
          },
        ),
      );

      if (!mounted) return;
      if (assignedStartNumber != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran berhasil! Nomor balap: '
              '#${assignedStartNumber!.toString().padLeft(3, '0')}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka pembayaran: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningPayment = false);
    }
  }

  Widget _buildPendingPaymentCard(EventRegistrationModel reg) {
    final isMidtrans = reg.paymentProofUrl.startsWith('MIDTRANS');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      size: 12,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMidtrans
                          ? 'MENUNGGU PEMBAYARAN MIDTRANS'
                          : 'MENUNGGU VERIFIKASI BENDAHARA',
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reg.bikeName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Piston: ${reg.pistonDiameterMm.toStringAsFixed(1)} mm • Rider: ${reg.riderName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Text(
            isMidtrans
                ? 'Pendaftaran sudah tersimpan, tetapi pembayaran Midtrans '
                      'belum selesai. Tekan tombol di bawah untuk membayar. '
                      'Nomor balap resmi dan QR kehadiran akan terbit otomatis '
                      'setelah pembayaran lunas (settlement).'
                : 'Bukti transfer pendaftaran Anda sedang ditinjau oleh '
                      'Bendahara (Dika). Nomor balap resmi (#001 dst) dan QR '
                      'Kehadiran akan terbit secara otomatis setelah pembayaran '
                      'disahkan.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          if (isMidtrans) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isOpeningPayment
                    ? null
                    : () => _openMidtransPayment(reg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isOpeningPayment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.payment, size: 16, color: Colors.white),
                label: Text(
                  _isOpeningPayment
                      ? 'MENYIAPKAN PEMBAYARAN...'
                      : 'BAYAR VIA MIDTRANS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 12, color: Colors.red.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'BUKTI PEMBAYARAN DITOLAK',
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
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reg.bikeName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Alasan Penolakan: ${reg.paymentRejectionReason ?? "Struk transfer tidak valid atau foto buram"}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showReuploadDialog(reg),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.cloud_upload_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'UNGGAH ULANG BUKTI BAYAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'UNGGAH ULANG BUKTI BAYAR',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan tautan URL foto struk transfer baru untuk diverifikasi ulang oleh Bendahara (Dika):',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'BATAL',
                style: TextStyle(color: AppColors.textMuted),
              ),
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
                              content: Text(
                                'Bukti transfer berhasil dikirim ulang! Menunggu verifikasi.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'KIRIM ULANG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingLiveBanner(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withValues(alpha: 0.12),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  event.imageUrl.isNotEmpty ? event.imageUrl : 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 180, color: Colors.grey.shade300),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                onPressed: widget.onOpenPodium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'LIHAT PODIUM KEJUARAAN',
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
