import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';

/// Widget Kartu Event Resmi DragHub (Milik Alfa / Sekretaris)
/// Menampilkan informasi event balap, kelas (Tipe + Piston + Braket),
/// serta sisa kuota dinamis sesuai PRD v1.4.
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final String? actionButtonText;
  final VoidCallback? onActionButtonPressed;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.actionButtonText,
    this.onActionButtonPressed,
  });

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor() {
    switch (event.status) {
      case 'PUBLISHED':
        return Colors.green.shade700;
      case 'ONGOING':
        return Colors.red.shade700;
      case 'COMPLETED':
        return Colors.blueGrey;
      case 'DRAFT':
        return Colors.orange.shade800;
      case 'REJECTED':
        return Colors.red.shade900;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel() {
    switch (event.status) {
      case 'PUBLISHED':
        return event.remainingQuota > 0 ? 'PENDAFTARAN BUKA' : 'KUOTA PENUH';
      case 'ONGOING':
        return 'PADDOCK LIVE';
      case 'COMPLETED':
        return 'EVENT SELESAI';
      case 'DRAFT':
        return 'DRAFT (REVIEW)';
      case 'REJECTED':
        return 'DITOLAK';
      default:
        return event.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double quotaProgress = event.quota > 0
        ? (event.registeredCount / event.quota).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. BANNER POSTER & STATUS OVERLAY ---
              Stack(
                children: [
                  Image.network(
                    event.imageUrl.isNotEmpty
                        ? event.imageUrl
                        : 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: AppColors.segmentBackground,
                      child: const Center(
                        child: Icon(Icons.two_wheeler, size: 48, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  // Badge Status (Kiri Atas)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Chip Kelas Balap (Kanan Atas)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${event.vehicleType} • ${event.maxPistonDiameterMm.toStringAsFixed(0)}MM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  // Judul & Lokasi Event (Kiri Bawah Gambar)
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- 2. INFORMASI SPESIFIKASI KELAS & TANGGAL ---
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      icon: Icons.calendar_today_outlined,
                      title: 'TANGGAL',
                      value: _formatDate(event.eventDate),
                    ),
                    _buildInfoColumn(
                      icon: Icons.timer_outlined,
                      title: 'BRAKET',
                      value: '${event.bracketSeconds.toStringAsFixed(0)} Detik',
                    ),
                    _buildInfoColumn(
                      icon: Icons.payments_outlined,
                      title: 'BIAYA',
                      value: _formatCurrency(event.registrationFee),
                      valueColor: AppColors.primaryMaroon,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderLight),

              // --- 3. KUOTA & SISA KUOTA (KUNCI PRD v1.4) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.group_outlined, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            const Text(
                              'SISA KUOTA:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.remainingQuota} SLOT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: event.remainingQuota > 0
                                    ? AppColors.primaryMaroon
                                    : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${event.registeredCount} / ${event.quota} Lunas',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar Kuota
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: quotaProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.segmentBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          event.remainingQuota > 0
                              ? AppColors.primaryMaroon
                              : Colors.red.shade800,
                        ),
                      ),
                    ),

                    // Tombol Aksi Opsional
                    if (actionButtonText != null && onActionButtonPressed != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onActionButtonPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            actionButtonText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

