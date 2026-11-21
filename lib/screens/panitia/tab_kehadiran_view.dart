import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/attendance_service.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

/// Tab Verifikasi Kehadiran & Absensi Hari-H (Modul Milik Alfa / Sekretaris)
/// Memverifikasi kehadiran pembalap berstatus Lunas dan menutup verifikasi kehadiran.
class TabKehadiranView extends StatefulWidget {
  const TabKehadiranView({super.key});

  @override
  State<TabKehadiranView> createState() => _TabKehadiranViewState();
}

class _TabKehadiranViewState extends State<TabKehadiranView> {
  final AttendanceService _attendanceService = AttendanceService();
  final EventService _eventService = EventService();

  String? _selectedEventId;
  final TextEditingController _scanInputCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scanInputCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _handleCheckIn(String registrationId) async {
    setState(() => _isProcessing = true);
    try {
      await _attendanceService.checkInRider(registrationId);
      _showMessage('Pembalap berhasil diverifikasi HADIR!');
      _scanInputCtrl.clear();
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmCloseAttendance(EventModel event) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Tutup Verifikasi Kehadiran?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Peserta lunas yang belum hadir akan otomatis DICORET (ABSENT). '
          'Mereka tidak dapat melanjutkan ke meja Scrutineering maupun balapan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Tutup Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final count = await _attendanceService.closeAttendance(event.eventId);
        _showMessage(
          'Verifikasi kehadiran resmi ditutup. $count peserta dicoret.',
        );
      } catch (e) {
        _showMessage('Gagal menutup kehadiran: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
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
                // Header Modul Kehadiran
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFIKASI KEHADIRAN PADDOCK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Modul Sekretaris • Scan QR & Validasi Hari-H',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Pilih Event
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
                                    '${e.title} (${e.className})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedEventId = val);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Bar Tombol Aksi Kehadiran & Status Penutupan
                if (currentEvent != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: currentEvent.isAttendanceClosed
                                    ? Colors.red
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentEvent.isAttendanceClosed
                                  ? 'KEHADIRAN DITUTUP'
                                  : 'ABSENSI DIBUKA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: currentEvent.isAttendanceClosed
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (!currentEvent.isAttendanceClosed)
                          OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _confirmCloseAttendance(currentEvent!),
                            icon: const Icon(
                              Icons.lock_clock,
                              size: 14,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'TUTUP KEHADIRAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Form Scan / Input QR ID
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scanInputCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Tempel / Input Registration ID hasil scan QR...',
                            hintStyle: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.qr_code_scanner,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty)
                              _handleCheckIn(val.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                if (_scanInputCtrl.text.trim().isNotEmpty) {
                                  _handleCheckIn(_scanInputCtrl.text.trim());
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'HADIR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Daftar Peserta Lunas
                Expanded(
                  child: _selectedEventId == null
                      ? const Center(
                          child: Text('Pilih event terlebih dahulu.'),
                        )
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _attendanceService.getPaidRegistrationsStream(
                            _selectedEventId!,
                          ),
                          builder: (context, regSnapshot) {
                            if (regSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryMaroon,
                                ),
                              );
                            }

                            final list = regSnapshot.data ?? [];
                            if (list.isEmpty) {
                              return Center(
                                child: Text(
                                  'Belum ada peserta yang lunas di event ini.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final rider = list[index];
                                final regId = rider['registrationId'] ?? '';
                                final startNumber =
                                    rider['assignedStartNumber'];
                                final startNumberStr = startNumber != null
                                    ? '#${startNumber.toString().padLeft(3, '0')}'
                                    : '---';
                                final attendance =
                                    rider['attendanceStatus'] ?? 'PENDING';

                                Color statusBg;
                                Color statusFg;
                                String statusLabel;

                                if (attendance == 'PRESENT') {
                                  statusBg = Colors.green.shade50;
                                  statusFg = Colors.green.shade800;
                                  statusLabel = 'HADIR';
                                } else if (attendance == 'ABSENT') {
                                  statusBg = Colors.red.shade50;
                                  statusFg = Colors.red.shade800;
                                  statusLabel = 'DICORET (ABSENT)';
                                } else {
                                  statusBg = Colors.orange.shade50;
                                  statusFg = Colors.orange.shade800;
                                  statusLabel = 'BELUM HADIR';
                                }

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.segmentBackground,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              '${rider['bikeName'] ?? ''} • Piston ${rider['pistonDiameterMm'] ?? 0} mm',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (attendance == 'PENDING')
                                        ElevatedButton(
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _handleCheckIn(regId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade700,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'HADIRKAN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusFg,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
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
