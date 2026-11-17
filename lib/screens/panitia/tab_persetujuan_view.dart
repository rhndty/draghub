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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', whereIn: const ['DRAFT', 'PUBLISHED'])
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
          return const Center(child: Text('Tidak ada event untuk diproses.'));
        }

        return ListView.separated(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String? ?? 'Event tanpa nama',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['location'] as String? ?? 'Lokasi belum diisi'} · $status',
                    ),
                    const SizedBox(height: 12),
                    if (isWorking)
                      const LinearProgressIndicator(
                        color: AppColors.primaryMaroon,
                      )
                    else if (status == 'DRAFT')
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: isBusy
                                ? null
                                : () => _runAction(
                              event.id,
                              () => _eventStatusService.approveDraft(event.id),
                              'Event disetujui dan dipublikasikan.',
                            ),
                            child: const Text('Setujui'),
                          ),
                          OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => _runAction(
                              event.id,
                              () => _eventStatusService.rejectDraft(event.id),
                              'Draft event ditolak.',
                            ),
                            child: const Text('Tolak'),
                          ),
                        ],
                      )
                    else if (status == 'PUBLISHED')
                      FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _runAction(
                          event.id,
                          () => _eventStatusService.startEvent(event.id),
                          'Event dimulai.',
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Mulai Event'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
