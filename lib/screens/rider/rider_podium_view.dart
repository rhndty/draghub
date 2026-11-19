import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';

/// Tampilan Podium Resmi Kejuaraan (Milik Rider / Pembalap)
/// Sesuai PRD v1.4 (Bab 4.7 & 5) & ERD v1.4:
/// - Realtime leaderboard ditiadakan untuk mencegah perselisihan paddock
/// - Hanya menampilkan juara 1 s.d 3 setelah event berstatus 'COMPLETED'
/// - Membaca snapshot data dari `events.podium`
/// - Menampilkan nama pembalap, nomor balap, nama motor, Reaction Time, Elapsed Time, dan Total Time
class RiderPodiumView extends StatefulWidget {
  const RiderPodiumView({super.key});

  @override
  State<RiderPodiumView> createState() => _RiderPodiumViewState();
}

class _RiderPodiumViewState extends State<RiderPodiumView> {
  final EventService _eventService = EventService();
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getEventsStream(status: 'COMPLETED'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            ),
          );
        }

        final completedEvents = snapshot.data ?? [];

        if (completedEvents.isEmpty) {
          return _buildNoCompletedEventsState();
        }

        // Tentukan event yang aktif dipilih
        final currentEvent = completedEvents.firstWhere(
          (e) => e.eventId == _selectedEventId,
          orElse: () => completedEvents.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SELECTOR EVENT JIKA TERDAPAT LEBIH DARI SATU EVENT COMPLETED
            if (completedEvents.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentEvent.eventId,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primaryMaroon,
                    ),
                    items: completedEvents.map((ev) {
                      return DropdownMenuItem<String>(
                        value: ev.eventId,
                        child: Text(
                          ev.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() => _selectedEventId = newId);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. KARTU RINGKASAN KEJUARAAN RESMI
            _buildEventHeaderCard(currentEvent),
            const SizedBox(height: 20),

            // 3. DAFTAR JUARA PODIUM (JUARA 1, 2, 3)
            Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'PODIUM RESMI JUARA 1 - 3',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildPodiumContent(currentEvent),

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildEventHeaderCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'STATUS: RESMI SELESAI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'DISAHKAN RACE DIRECTOR',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                event.location,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.sports_score_outlined,
                size: 14,
                color: AppColors.primaryMaroon,
              ),
              const SizedBox(width: 4),
              Text(
                'Kelas: ${event.className}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumContent(EventModel event) {
    final podiumList = event.podium;

    if (podiumList == null || podiumList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: const [
            Icon(Icons.hourglass_empty, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Menunggu Pengesahan Podium',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Rekapitulasi telemetri balap sedang diverifikasi oleh Race Director & Wakil Ketua.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: podiumList.map((entry) {
        final int rank = (entry['rank'] as num?)?.toInt() ?? 1;
        final String riderName = (entry['riderName'] ?? 'Pembalap').toString();
        final String startNumber = (entry['startNumber'] ?? '-').toString();
        final String bikeName = (entry['bikeName'] ?? 'Motor Balap').toString();
        final double reactionTime =
            (entry['reactionTime'] as num?)?.toDouble() ?? 0.0;
        final double elapsedTime =
            (entry['elapsedTime'] as num?)?.toDouble() ?? 0.0;
        final double totalTime =
            (entry['totalTime'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildPodiumCard(
            rank: rank,
            riderName: riderName,
            startNumber: startNumber,
            bikeName: bikeName,
            reactionTime: reactionTime,
            elapsedTime: elapsedTime,
            totalTime: totalTime,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPodiumCard({
    required int rank,
    required String riderName,
    required String startNumber,
    required String bikeName,
    required double reactionTime,
    required double elapsedTime,
    required double totalTime,
  }) {
    Color medalColor;
    Color medalBg;
    String rankLabel;
    String trophyEmoji;

    switch (rank) {
      case 1:
        medalColor = const Color(0xFFD4AF37); // Gold
        medalBg = const Color(0xFFFFF9E6);
        rankLabel = 'JUARA 1';
        trophyEmoji = '🥇';
        break;
      case 2:
        medalColor = const Color(0xFF9E9E9E); // Silver
        medalBg = const Color(0xFFF5F5F5);
        rankLabel = 'JUARA 2';
        trophyEmoji = '🥈';
        break;
      case 3:
        medalColor = const Color(0xFFCD7F32); // Bronze
        medalBg = const Color(0xFFFDF3EB);
        rankLabel = 'JUARA 3';
        trophyEmoji = '🥉';
        break;
      default:
        medalColor = AppColors.textMuted;
        medalBg = Colors.grey.shade100;
        rankLabel = 'POSISI $rank';
        trophyEmoji = '🏁';
    }

    final formattedNumber = startNumber.startsWith('#')
        ? startNumber
        : '#${startNumber.padLeft(3, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? medalColor.withValues(alpha: 0.6)
              : AppColors.borderLight,
          width: rank == 1 ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: rank == 1
                ? medalColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar Kartu Podium
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: medalBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Text(trophyEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  rankLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: medalColor == const Color(0xFFD4AF37)
                        ? const Color(0xFF8A6D00)
                        : medalColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formattedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Rider & Hasil Waktu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            riderName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  bikeName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL WAKTU',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${totalTime.toStringAsFixed(3)}s',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryMaroon,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 10),

                // Telemetri RT & ET
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTimeMetric(
                      label: 'REACTION TIME (RT)',
                      value: '${reactionTime.toStringAsFixed(3)}s',
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppColors.borderLight,
                    ),
                    _buildTimeMetric(
                      label: 'ELAPSED TIME (ET)',
                      value: '${elapsedTime.toStringAsFixed(3)}s',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildNoCompletedEventsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 14),
          Text(
            'Belum Ada Podium Resmi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hasil podium juara 1, 2, dan 3 akan ditampilkan setelah kejuaraan selesai (status COMPLETED) dan disahkan oleh Race Director.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Sesuai regulasi PRD v1.4, leaderboard realtime ditiadakan demi menjaga sportivitas dan menghindari perselisihan di area paddock.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
