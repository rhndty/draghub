import 'package:flutter/material.dart';
import '../models/event_registration_model.dart';
import '../theme/app_colors.dart';

/// Kartu Balap Resmi & QR Code Kehadiran Paddock (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Nomor balap resmi urut lunas (#001 dst)
/// - QR Code memuat registrationId
/// - Status Kehadiran (PENDING / PRESENT / ABSENT)
/// - Status Scrutineering (PENDING / PASSED / DISQUALIFIED beserta alasan & ukuran aktual)
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
    if (num == null) return '---';
    return '#${num.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDisqualified =
        registration.scrutineeringStatus == ScrutineeringStatus.disqualified;
    final isPassedScrut =
        registration.scrutineeringStatus == ScrutineeringStatus.passed;
    final isPresent =
        registration.attendanceStatus == AttendanceStatus.present;
    final isAbsent =
        registration.attendanceStatus == AttendanceStatus.absent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDisqualified
              ? Colors.red.shade400
              : isPassedScrut
                  ? Colors.green.shade400
                  : AppColors.borderLight,
          width: isDisqualified || isPassedScrut ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDisqualified ? Colors.red : AppColors.primaryMaroon)
                .withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Kartu Balap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDisqualified
                  ? Colors.red.shade700
                  : isPassedScrut
                      ? Colors.green.shade700
                      : AppColors.primaryMaroon,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PADDOCK PASS & NOMOR BALAP',
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
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    registration.vehicleType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Info Rider & Motor
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PEMBALAP',
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
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'KENDARAAN & SPESIFIKASI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${registration.bikeName} • ${registration.pistonDiameterMm.toStringAsFixed(1)}mm',
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

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 20),

                // QR Code Kehadiran Paddock
                if (!isAbsent) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(registration.registrationId)}',
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 160,
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryMaroon,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 160,
                                height: 160,
                                color: Colors.grey.shade100,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2, size: 48, color: AppColors.textMuted),
                                    SizedBox(height: 4),
                                    Text('QR Code', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          registration.registrationId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pindai QR di meja paddock untuk verifikasi kehadiran hari-H',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],

                const SizedBox(height: 16),

                // BADGE STATUS KEHADIRAN & SCRUTINEERING
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusPill(
                        title: 'KEHADIRAN',
                        value: isPresent
                            ? 'HADIR'
                            : isAbsent
                                ? 'DICORET'
                                : 'PENDING',
                        color: isPresent
                            ? Colors.green
                            : isAbsent
                                ? Colors.red
                                : Colors.amber.shade700,
                        icon: isPresent
                            ? Icons.check_circle
                            : isAbsent
                                ? Icons.cancel
                                : Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusPill(
                        title: 'SCRUTINEERING',
                        value: isPassedScrut
                            ? 'LOLOS'
                            : isDisqualified
                                ? 'DISKUALIFIKASI'
                                : 'PENDING',
                        color: isPassedScrut
                            ? Colors.green
                            : isDisqualified
                                ? Colors.red
                                : Colors.amber.shade700,
                        icon: isPassedScrut
                            ? Icons.verified
                            : isDisqualified
                                ? Icons.gavel
                                : Icons.engineering,
                      ),
                    ),
                  ],
                ),

                // BANNER DISKUALIFIKASI KHUSUS JIKA OVERSPEC
                if (isDisqualified) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red.shade700, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'BERITA ACARA DISKUALIFIKASI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (registration.measuredPistonMm != null)
                          Text(
                            'Piston Terukur: ${registration.measuredPistonMm!.toStringAsFixed(2)} mm',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Alasan: ${registration.disqualificationReason ?? "Overspec diameter piston"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '* Jika merasa salah ukur, silakan ajukan scrut ulang kepada Ketua/Wakil sebelum event dimulai.',
                          style: TextStyle(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
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

  Widget _buildStatusPill({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 12, color: color),
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

