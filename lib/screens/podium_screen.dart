import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/podium_service.dart';
import '../theme/app_colors.dart';

/// Layar podium resmi milik Ferdi.
/// Podium hanya ditampilkan untuk event COMPLETED dan snapshot yang tersedia.
class PodiumScreen extends StatelessWidget {
  const PodiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'PODIUM RESMI',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: eventService.getEventsStream(status: 'COMPLETED'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryMaroon,
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return _messageCard(
              Icons.emoji_events_outlined,
              'Belum Ada Podium Resmi',
              'Podium akan tampil setelah event selesai.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _eventCard(events[index]),
          );
        },
      ),
    );
  }

  Widget _eventCard(EventModel event) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PodiumService().getPodiumStream(event.eventId),
      builder: (context, snapshot) {
        final podium = snapshot.data ?? const <Map<String, dynamic>>[];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${event.location} • ${event.className}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (podium.isEmpty)
                const Text(
                  'Snapshot podium belum tersedia.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ...podium.map(_podiumRow),
            ],
          ),
        );
      },
    );
  }

  Widget _podiumRow(Map<String, dynamic> entry) {
    final rank = (entry['rank'] as num?)?.toInt() ?? 0;
    final riderName = (entry['riderName'] ?? 'Pembalap').toString();
    final startNumber = (entry['startNumber'] ?? '-').toString();
    final totalTime = (entry['totalTime'] as num?)?.toDouble() ?? 0;
    final reactionTime = (entry['reactionTime'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: rank == 1 ? const Color(0xFFFFF9E6) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JUARA $rank • #$startNumber',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryMaroon,
                  ),
                ),
                Text(
                  riderName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${totalTime.toStringAsFixed(3)} s',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'RT ${reactionTime.toStringAsFixed(3)} s',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageCard(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
