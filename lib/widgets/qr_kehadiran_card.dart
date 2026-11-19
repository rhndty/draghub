import 'package:flutter/material.dart';

import '../models/event_registration_model.dart';
import '../theme/app_colors.dart';

/// Kartu Balap Resmi & QR Code Kehadiran Paddock (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 (Bab 4.4 & 4.5) & ERD v1.4 (Bab 2.4 & 3.3):
/// - Nomor balap urut lunas (#001 dst) terbit saat status pembayaran 'PAID'
/// - QR Code memuat registrationId untuk discan oleh Sekretaris/Petugas di tenda paddock
/// - Status Kehadiran (PENDING / PRESENT / ABSENT)
/// - Status Scrutineering (PENDING / PASSED / DISQUALIFIED dengan alasan dan hasil ukur jangka sorong)
class QrKehadiranCard extends StatelessWidget {
  final EventRegistrationModel registration;
  final String? eventTitle;

  const QrKehadiranCard({
    super.key,
    required this.registration,
    this.eventTitle,
  });

  String get _formattedStartNumber {
    final num = registration.assignedStartNumber;
    if (num == null) return '#---';
    return '#${num.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDisqualified =
        registration.scrutineeringStatus == ScrutineeringStatus.disqualified;
    final isPassedScrut =
        registration.scrutineeringStatus == ScrutineeringStatus.passed;
    final isPresent = registration.attendanceStatus == AttendanceStatus.present;
    final isAbsent = registration.attendanceStatus == AttendanceStatus.absent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDisqualified
              ? Colors.red.shade400
              : isPassedScrut
              ? Colors.green.shade500
              : AppColors.borderLight,
          width: isDisqualified || isPassedScrut ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDisqualified ? Colors.red : AppColors.primaryMaroon)
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- HEADER KARTU BALAP PADDOCK ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDisqualified
                  ? Colors.red.shade800
                  : isPassedScrut
                  ? Colors.green.shade700
                  : AppColors.primaryMaroon,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PADDOCK PASS & NOMOR BALAP RESMI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedStartNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'KELAS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        registration.vehicleType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Identitas Pembalap & Motor
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NAMA PEMBALAP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            registration.riderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'KENDARAAN & SPESIFIKASI PISTON',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${registration.bikeName} • Piston ${registration.pistonDiameterMm.toStringAsFixed(1)} mm',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),

                // --- TAMPILAN QR CODE KEHADIRAN (PRD 4.5) ---
                if (!isAbsent) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(registration.registrationId)}',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 150,
                                height: 150,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryMaroon,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackQrCode(
                                registration.registrationId,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          registration.registrationId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tunjukkan QR ini ke Sekretaris di tenda paddock untuk verifikasi kehadiran hari-H',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // --- DUA BADGE STATUS: KEHADIRAN & SCRUTINEERING ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusPill(
                        title: 'KEHADIRAN',
                        value: isPresent
                            ? 'HADIR DI SIRKUIT'
                            : isAbsent
                            ? 'DICORET (ABSENT)'
                            : 'MENUNGGU SCAN',
                        color: isPresent
                            ? Colors.green.shade700
                            : isAbsent
                            ? Colors.red.shade700
                            : Colors.amber.shade800,
                        icon: isPresent
                            ? Icons.check_circle
                            : isAbsent
                            ? Icons.cancel
                            : Icons.qr_code_scanner,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatusPill(
                        title: 'SCRUTINEERING',
                        value: isPassedScrut
                            ? 'LOLOS SCRUT'
                            : isDisqualified
                            ? 'DISKUALIFIKASI'
                            : 'BELUM SCRUT',
                        color: isPassedScrut
                            ? Colors.green.shade700
                            : isDisqualified
                            ? Colors.red.shade700
                            : Colors.amber.shade800,
                        icon: isPassedScrut
                            ? Icons.verified
                            : isDisqualified
                            ? Icons.gavel
                            : Icons.straighten,
                      ),
                    ),
                  ],
                ),

                // --- KARTU MERAH DISKUALIFIKASI (PRD 3.3 & ERD 3.4) ---
                if (isDisqualified) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'BERITA ACARA DISKUALIFIKASI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (registration.measuredPistonMm != null) ...[
                          Text(
                            'Hasil Ukur Jangka Sorong: ${registration.measuredPistonMm!.toStringAsFixed(2)} mm',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Alasan Resmi: ${registration.disqualificationReason ?? "Piston melebihi batas ketentuan kelas balap (overspec)"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text(
                          '* Sesuai regulasi PRD DragHub, biaya pendaftaran tidak dapat dikembalikan. Jika merasa salah ukur, Anda berhak mengajukan permohonan Scrut Ulang langsung kepada Ketua atau Wakil Ketua di paddock sebelum balap dimulai.',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackQrCode(String data) {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey.shade100,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 64, color: AppColors.primaryMaroon),
          SizedBox(height: 6),
          Text(
            'QR PADDOCK PASS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
