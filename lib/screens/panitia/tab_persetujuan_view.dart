import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/event_status_service.dart';
import '../../theme/app_colors.dart';

class TabPersetujuanView extends StatefulWidget {
  const TabPersetujuanView({super.key});

  @override
  State<TabPersetujuanView> createState() => _TabPersetujuanViewState();
}

class _TabPersetujuanViewState extends State<TabPersetujuanView> {
  final EventStatusService _eventStatusService = EventStatusService();
  String? _workingEventId;

  Future<void> _runAction(
    String eventId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _workingEventId = eventId);
    try {
      await action();
      if (mounted) _showMessage(successMessage);
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code, isError: true);
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _workingEventId = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'KONTROL & PERSETUJUAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: AppColors.primaryMaroon,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('status', whereIn: const ['DRAFT', 'PUBLISHED', 'ONGOING'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat event: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryMaroon,
              ),
            );
          }

          final events = snapshot.data?.docs ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada event untuk diproses.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data();
              final status = data['status'] as String? ?? 'UNKNOWN';
              final isWorking = _workingEventId == event.id;
              final isBusy = _workingEventId != null;

              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['title'] as String? ?? 'Event tanpa nama',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'DRAFT'
                                  ? Colors.orange.shade100
                                  : status == 'PUBLISHED'
                                      ? Colors.blue.shade100
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'DRAFT'
                                    ? Colors.orange.shade900
                                    : status == 'PUBLISHED'
                                        ? Colors.blue.shade900
                                        : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['location'] as String? ?? 'Lokasi belum diisi',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isWorking)
                        const LinearProgressIndicator(
                          color: AppColors.primaryMaroon,
                        )
                      else if (status == 'DRAFT')
                        Row(
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () => _runAction(
                                        event.id,
                                        () => _eventStatusService
                                            .approveDraft(event.id),
                                        'Event disetujui dan dipublikasikan.',
                                      ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Setujui'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () => _runAction(
                                        event.id,
                                        () => _eventStatusService
                                            .rejectDraft(event.id),
                                        'Draft event ditolak.',
                                      ),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Tolak'),
                            ),
                          ],
                        )
                      else if (status == 'PUBLISHED')
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryMaroon,
                          ),
                          onPressed: isBusy
                              ? null
                              : () => _runAction(
                                    event.id,
                                    () => _eventStatusService
                                        .startEvent(event.id),
                                    'Event dimulai (status: ONGOING).',
                                  ),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Mulai Event (ONGOING)'),
                        )
                      else if (status == 'ONGOING')
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                          ),
                          onPressed: isBusy
                              ? null
                              : () => _runAction(
                                    event.id,
                                    () => _eventStatusService.completeEvent(
                                      eventId: event.id,
                                      podium: const [],
                                    ),
                                    'Event selesai (status: COMPLETED).',
                                  ),
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text('Akhiri Event (COMPLETED)'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
