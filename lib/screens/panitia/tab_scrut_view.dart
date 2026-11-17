import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/scrut_service.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

/// Tab Meja Inspeksi Fisik / Scrutineering (Modul Milik Alfa / Sekretaris)
/// Mengukur piston sebelum balap dan dialog konfirmasi diskualifikasi anti-misclick.
class TabScrutView extends StatefulWidget {
  const TabScrutView({super.key});

  @override
  State<TabScrutView> createState() => _TabScrutViewState();
}

class _TabScrutViewState extends State<TabScrutView> {
  final ScrutService _scrutService = ScrutService();
  final EventService _eventService = EventService();

  String? _selectedEventId;
  bool _isProcessing = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openScrutDialog(Map<String, dynamic> rider, EventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ScrutInspectionDialog(
        rider: rider,
        event: event,
        onSubmit: (double measuredMm, String? reason) async {
          setState(() => _isProcessing = true);
          try {
            await _scrutService.submitScrutResult(
              registrationId: rider['registrationId'],
              measuredPistonMm: measuredMm,
              maxPistonDiameterMm: event.maxPistonDiameterMm,
              disqualificationReason: reason,
            );
            _showMessage(
              measuredMm <= event.maxPistonDiameterMm
                  ? 'Motor Lolos Scrutineering (PASSED)!'
                  : 'Peserta resmi DIDISKUALIFIKASI karena overspec.',
              isError: measuredMm > event.maxPistonDiameterMm,
            );
          } catch (e) {
            _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  void _showHistoryDialog(Map<String, dynamic> rider) {
    final history = rider['scrutineeringHistory'] as List<dynamic>? ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Riwayat Scrutineering: ${rider['riderName']}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: history.isEmpty
            ? const Text('Belum ada riwayat pemeriksaan.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final item = history[idx] as Map<String, dynamic>;
                    final isPassed = item['status'] == 'PASSED';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isPassed ? Icons.check_circle : Icons.cancel,
                        color: isPassed ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        'Piston ${item['measuredPistonMm']} mm (${item['status']})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      subtitle: Text(
                        'Alasan: ${item['reason'] ?? '-'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventService.getEventsStream(),
          builder: (context, eventSnapshot) {
            final events = eventSnapshot.data ?? [];
            if (_selectedEventId == null && events.isNotEmpty) {
              _selectedEventId = events.first.eventId;
            }

            EventModel? currentEvent;
            if (_selectedEventId != null && events.isNotEmpty) {
              currentEvent = events.firstWhere(
                (e) => e.eventId == _selectedEventId,
                orElse: () => events.first,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEJA SCRUTINEERING FISIK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Modul Sekretaris • Inspeksi Piston & Dialog Diskualifikasi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Event
                      if (events.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.segmentBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedEventId,
                              items: events.map((e) {
                                return DropdownMenuItem(
                                  value: e.eventId,
                                  child: Text(
                                    '${e.title} (Maks ${e.maxPistonDiameterMm.toStringAsFixed(0)}mm)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedEventId = val),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Batas Regulasi Info Bar
                if (currentEvent != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, size: 16, color: AppColors.primaryMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Regulasi: ${currentEvent.vehicleType} • Batas Maksimal Piston: ${currentEvent.maxPistonDiameterMm.toStringAsFixed(0)} mm (Tanpa Toleransi)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryMaroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Antrean Scrut (Hanya yang HADIR)
                Expanded(
                  child: _selectedEventId == null
                      ? const Center(child: Text('Pilih event.'))
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _scrutService.getScrutQueueStream(_selectedEventId!),
                          builder: (context, queueSnapshot) {
                            if (queueSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
                            }

                            final queue = queueSnapshot.data ?? [];
                            if (queue.isEmpty) {
                              return Center(
                                child: Text(
                                  'Belum ada peserta yang hadir untuk discrutineering.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: queue.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final rider = queue[index];
                                final startNumber = rider['assignedStartNumber'];
                                final startNumberStr = startNumber != null
                                    ? '#${startNumber.toString().padLeft(3, '0')}'
                                    : '---';

                                final scrutStatus = rider['scrutineeringStatus'] ?? 'PENDING';
                                final measured = rider['measuredPistonMm'];

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: scrutStatus == 'DISQUALIFIED'
                                          ? Colors.red.shade300
                                          : (scrutStatus == 'PASSED'
                                              ? Colors.green.shade300
                                              : AppColors.borderLight),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.segmentBackground,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            startNumberStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: AppColors.primaryMaroon,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rider['riderName'] ?? 'Pembalap',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            Text(
                                              'Motor: ${rider['bikeName'] ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            if (measured != null)
                                              Text(
                                                'Terukur: $measured mm',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: scrutStatus == 'PASSED'
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Status / Tombol
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: _isProcessing
                                                ? null
                                                : () => _openScrutDialog(rider, currentEvent!),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: scrutStatus == 'PENDING'
                                                  ? AppColors.primaryMaroon
                                                  : Colors.blueGrey,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              scrutStatus == 'PENDING' ? 'UKUR PISTON' : 'SCRUT ULANG',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (rider['scrutineeringHistory'] != null)
                                            InkWell(
                                              onTap: () => _showHistoryDialog(rider),
                                              child: const Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Riwayat',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dialog Inspeksi Scrutineering (Mendukung Konfirmasi Diskualifikasi Anti-Misclick)
class _ScrutInspectionDialog extends StatefulWidget {
  final Map<String, dynamic> rider;
  final EventModel event;
  final Function(double measuredMm, String? reason) onSubmit;

  const _ScrutInspectionDialog({
    required this.rider,
    required this.event,
    required this.onSubmit,
  });

  @override
  State<_ScrutInspectionDialog> createState() => _ScrutInspectionDialogState();
}

class _ScrutInspectionDialogState extends State<_ScrutInspectionDialog> {
  final TextEditingController _pistonCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  double? _measuredMm;

  @override
  void dispose() {
    _pistonCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMm = widget.event.maxPistonDiameterMm;
    final isOverspec = _measuredMm != null && _measuredMm! > maxMm;
    final diff = isOverspec ? (_measuredMm! - maxMm) : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOverspec ? Colors.red.shade800 : AppColors.primaryMaroon,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            Icon(
              isOverspec ? Icons.warning_amber_rounded : Icons.straighten,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOverspec ? 'PERINGATAN DISKUALIFIKASI' : 'Inspeksi Meja Scrut',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rider: ${widget.rider['riderName']} (${widget.rider['bikeName']})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Batas Regulasi Event: ${maxMm.toStringAsFixed(0)} mm',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Input Hasil Ukur Piston
            const Text(
              'HASIL UKUR PISTON FISIK (MM)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _pistonCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Contoh: 62.5 atau 64.0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _measuredMm = double.tryParse(val.replaceAll(',', '.'));
                });
              },
            ),
            const SizedBox(height: 14),

            // Banner Hasil Perhitungan Realtime
            if (_measuredMm != null) ...[
              if (!isOverspec)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Piston ${_measuredMm!} mm <= $maxMm mm (Lolos Regulasi)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Banner Merah Overspec
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OVERSPEC: +${diff.toStringAsFixed(2)} mm di atas batas!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Piston fisik ${_measuredMm!} mm melebihi batas regulasi event ($maxMm mm). '
                        'Sesuai PRD v1.4, toleransi adalah nol.',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Kolom Wajib Alasan Diskualifikasi
                const Text(
                  'ALASAN RESMI DISKUALIFIKASI (WAJIB)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan alasan resmi, misal: Piston terukur 64.5 mm melebihi batas 63 mm',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal / Ukur Ulang'),
        ),
        ElevatedButton(
          onPressed: (_measuredMm == null || (isOverspec && _reasonCtrl.text.trim().isEmpty))
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSubmit(_measuredMm!, _reasonCtrl.text.trim());
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isOverspec ? Colors.red.shade800 : Colors.green.shade800,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            isOverspec ? 'TETAPKAN DISKUALIFIKASI' : 'LOLOSKAN MOTOR',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

