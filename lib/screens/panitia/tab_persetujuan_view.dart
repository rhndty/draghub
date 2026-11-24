import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/event_status_service.dart';
import '../../services/podium_service.dart';
import '../../theme/app_colors.dart';

class TabPersetujuanView extends StatefulWidget {
  const TabPersetujuanView({super.key});

  @override
  State<TabPersetujuanView> createState() => _TabPersetujuanViewState();
}

class _TabPersetujuanViewState extends State<TabPersetujuanView> {
  final EventStatusService _eventStatusService = EventStatusService();
  final PodiumService _podiumService = PodiumService();
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

  /// Mengakhiri event: hitung podium lebih dulu lewat [PodiumService] milik
  /// Ferdi, tampilkan pratinjau untuk disetujui, lalu simpan status COMPLETED
  /// beserta snapshot podium dalam satu transisi.
  Future<void> _finalizeEvent(String eventId, String title) async {
    List<Map<String, dynamic>>? podium;

    setState(() => _workingEventId = eventId);
    try {
      podium = await _podiumService.calculatePodium(eventId);
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code, isError: true);
      return;
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
      return;
    } finally {
      if (mounted) setState(() => _workingEventId = null);
    }

    if (!mounted) return;

    final confirmed = await _showFinalizeDialog(title, podium);
    if (confirmed != true || !mounted) return;

    final podiumSnapshot = podium;
    await _runAction(
      eventId,
      () => _eventStatusService.completeEvent(
        eventId: eventId,
        podium: podiumSnapshot,
      ),
      podiumSnapshot.isEmpty
          ? 'Event selesai (COMPLETED) tanpa hasil podium.'
          : 'Event selesai (COMPLETED). Podium juara 1-3 telah disimpan.',
    );
  }

  Future<bool?> _showFinalizeDialog(
    String title,
    List<Map<String, dynamic>> podium,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akhiri Event?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event "$title" akan berstatus COMPLETED. '
                'Hasil balap terkunci dan tidak dapat diubah lagi.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (podium.isEmpty)
                Text(
                  'Belum ada hasil VALID. Event tetap dapat diakhiri, '
                  'tetapi podium tidak akan ditampilkan.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                )
              else ...[
                const Text(
                  'Podium yang akan disahkan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...podium.map((entry) {
                  final rank = entry['rank'] ?? '-';
                  final riderName = entry['riderName'] ?? 'Pembalap';
                  final startNumber = entry['startNumber'] ?? '-';
                  final totalTime =
                      (entry['totalTime'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Juara $rank • $riderName (#$startNumber) — '
                      '${totalTime.toStringAsFixed(3)}s',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              podium.isEmpty ? 'Akhiri Tanpa Podium' : 'Akhiri & Sahkan',
            ),
          ),
        ],
      ),
    );
  }

  /// Menghitung ulang podium untuk event yang sudah COMPLETED tetapi belum
  /// punya snapshot podium (perbaikan event lama).
  Future<void> _recalculatePodium(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hitung Ulang Podium'),
        content: const Text(
          'Snapshot podium akan dihitung dari hasil balap VALID lalu '
          'disimpan ke event. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hitung Ulang'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _workingEventId = eventId);
    try {
      final podium = await _podiumService.calculateAndSavePodium(
        eventId,
        allowCompleted: true,
      );
      if (!mounted) return;
      _showMessage(
        podium.isEmpty
            ? 'Podium dihitung ulang, tetapi belum ada hasil VALID.'
            : 'Podium juara 1-3 berhasil disimpan.',
      );
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? error.code, isError: true);
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _workingEventId = null);
    }
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
            .where(
              'status',
              whereIn: const ['DRAFT', 'PUBLISHED', 'ONGOING', 'COMPLETED'],
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat event: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            );
          }

          // Event COMPLETED hanya ditampilkan bila snapshot podium belum
          // pernah dihitung, supaya Ketua/Wakil bisa memperbaiki data lama.
          final events = (snapshot.data?.docs ?? []).where((event) {
            final data = event.data();
            if (data['status'] != 'COMPLETED') return true;
            final podium = data['podium'];
            final hasSnapshot = podium is List && podium.isNotEmpty;
            final hasBeenCalculated = data['podiumCalculatedAt'] != null;
            return !hasSnapshot && !hasBeenCalculated;
          }).toList();
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
                      if (status == 'COMPLETED') ...[
                        const SizedBox(height: 6),
                        Text(
                          'Event sudah COMPLETED, tetapi snapshot podium '
                          'belum tersimpan.',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                                      () => _eventStatusService.approveDraft(
                                        event.id,
                                      ),
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
                                      () => _eventStatusService.rejectDraft(
                                        event.id,
                                      ),
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
                                  () =>
                                      _eventStatusService.startEvent(event.id),
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
                              : () => _finalizeEvent(
                                  event.id,
                                  data['title'] as String? ??
                                      'Event tanpa nama',
                                ),
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text('Akhiri Event (COMPLETED)'),
                        )
                      else if (status == 'COMPLETED')
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                          ),
                          onPressed: isBusy
                              ? null
                              : () => _recalculatePodium(event.id),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Hitung Ulang Podium'),
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
