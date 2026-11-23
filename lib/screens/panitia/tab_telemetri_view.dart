import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../models/event_registration_model.dart';
import '../../models/race_result_model.dart';
import '../../services/event_service.dart';
import '../../services/telemetry_service.dart';
import '../../theme/app_colors.dart';

/// Layar pencatatan hasil waktu balap milik Ofisial/Wakil.
class TabTelemetriView extends StatefulWidget {
  const TabTelemetriView({super.key});

  @override
  State<TabTelemetriView> createState() => _TabTelemetriViewState();
}

class _TabTelemetriViewState extends State<TabTelemetriView> {
  final _eventService = EventService();
  final _telemetryService = TelemetryService();

  String? _selectedEventId;
  EventRegistrationModel? _selectedRider;
  bool _processing = false;

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red.shade800 : Colors.green.shade800,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventService.getEventsStream(),
          builder: (context, eventSnapshot) {
            // Telemetri hanya bekerja pada event yang sudah dimulai oleh
            // Ketua/Wakil. Event DRAFT/PUBLISHED/COMPLETED tidak ditampilkan.
            final events = (eventSnapshot.data ?? [])
                .where((event) => event.status == 'ONGOING')
                .toList();
            if (_selectedEventId == null && events.isNotEmpty) {
              _selectedEventId = events.first.eventId;
            }
            EventModel? event;
            for (final item in events) {
              if (item.eventId == _selectedEventId) event = item;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text('PENCATATAN WAKTU BALAP', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.textDark, letterSpacing: -0.5,
                )),
                const SizedBox(height: 3),
                const Text('Modul Ofisial • Telemetri, Braket & Hasil Balap',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
                const SizedBox(height: 14),
                _eventDropdown(events),
                if (event != null) ...[
                  const SizedBox(height: 10),
                  _eventInfo(event),
                  const SizedBox(height: 16),
                  _eligibleSection(event),
                  const SizedBox(height: 16),
                  _historySection(event),
                ] else
                  _emptyCard('Belum ada event yang tersedia.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _eventDropdown(List<EventModel> events) {
    if (events.isEmpty) return _emptyCard('Event belum tersedia.');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.segmentBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: events.any((e) => e.eventId == _selectedEventId)
              ? _selectedEventId : events.first.eventId,
          items: events.map((e) => DropdownMenuItem(
            value: e.eventId,
            child: Text('${e.title} • ${e.status}', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold)),
          )).toList(),
          onChanged: (value) => setState(() {
            _selectedEventId = value;
            _selectedRider = null;
          }),
        ),
      ),
    );
  }

  Widget _eventInfo(EventModel event) {
    final active = event.status == 'ONGOING';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F7EF) : const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(active ? Icons.play_circle : Icons.lock_clock,
            color: active ? Colors.green.shade700 : Colors.red.shade700),
        const SizedBox(width: 10),
        Expanded(child: Text(
          active ? 'Event ONGOING • Hasil dapat dicatat atau dikoreksi.'
              : 'Event ${event.status} • Pencatatan hanya aktif saat ONGOING.',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        )),
        Text('Braket ${event.bracketSeconds.toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _eligibleSection(EventModel event) {
    return _sectionCard(
      title: 'PESERTA SIAP BALAP',
      icon: Icons.verified_user_outlined,
      child: StreamBuilder<List<EventRegistrationModel>>(
        stream: _telemetryService.getEligibleRegistrationsStream(event.eventId),
        builder: (context, snapshot) {
          // Pengaman UI tambahan: peserta tidak ditampilkan bila event belum
          // dimulai, walaupun stream registrations masih mengembalikan data.
          if (event.status != 'ONGOING') {
            return _emptyInside(
              'Pencatatan waktu hanya tersedia saat event berstatus ONGOING.',
            );
          }

          final riders = snapshot.data ?? [];
          if (riders.isEmpty) return _emptyInside('Belum ada peserta yang memenuhi syarat.');
          return Column(children: riders.map((rider) {
            final selected = _selectedRider?.registrationId == rider.registrationId;
            return InkWell(
              onTap: () => setState(() => _selectedRider = rider),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFDE8E8) : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: selected ? AppColors.primaryMaroon : AppColors.borderLight),
                ),
                child: Row(children: [
                  CircleAvatar(radius: 17, backgroundColor: AppColors.primaryMaroon,
                      child: Text('${rider.assignedStartNumber ?? '-'}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rider.riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('${rider.bikeName} • Lunas • Hadir • Lolos Scrut',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ])),
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selected ? AppColors.primaryMaroon : AppColors.textMuted),
                ]),
              ),
            );
          }).toList());
        },
      ),
    );
  }

  Widget _historySection(EventModel event) {
    return _sectionCard(
      title: 'RIWAYAT HASIL BALAP', icon: Icons.history,
      child: StreamBuilder<List<RaceResultModel>>(
        stream: _telemetryService.getResultsStream(event.eventId),
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];
          if (results.isEmpty) return _emptyInside('Belum ada hasil yang dicatat.');
          return Column(
            children: results.map((result) {
              return FutureBuilder<EventRegistrationModel?>(
                future: _telemetryService.getRegistration(result.registrationId),
                builder: (context, registrationSnapshot) {
                  final registration = registrationSnapshot.data;
                  final riderName = registration?.riderName ?? 'Memuat nama rider...';
                  final startNumber = registration?.assignedStartNumber;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _statusIcon(result.status),
                      color: _statusColor(result.status),
                    ),
                    title: Text(
                      '${startNumber == null ? '' : '#$startNumber • '}$riderName • ${result.totalTime.toStringAsFixed(3)} detik',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Lane ${result.lane} • RT ${result.reactionTime.toStringAsFixed(3)} • ${result.status.value}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _statusColor(result.status),
                      ),
                    ),
                    trailing: event.status == 'ONGOING'
                        ? IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editResult(event, result),
                          )
                        : null,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _openInput(EventModel event, {RaceResultModel? existing, RaceResultStatus? specialStatus}) {
    final rider = _selectedRider;
    if (rider == null) {
      _message('Pilih peserta terlebih dahulu.', error: true);
      return;
    }
    _showTimingDialog(event, rider, existing: existing, specialStatus: specialStatus);
  }

  void _editResult(EventModel event, RaceResultModel result) {
    _showTimingDialog(event, _selectedRider ?? EventRegistrationModel(
      registrationId: result.registrationId, eventId: event.eventId, userId: '', bikeId: '',
      riderName: result.registrationId, bikeName: '', vehicleType: '', pistonDiameterMm: 0,
      paymentProofUrl: '', paymentStatus: PaymentStatus.paid,
      attendanceStatus: AttendanceStatus.present,
      scrutineeringStatus: ScrutineeringStatus.passed, registeredAt: DateTime.now(),
    ), existing: result);
  }

  Future<void> _showTimingDialog(EventModel event, EventRegistrationModel rider,
      {RaceResultModel? existing, RaceResultStatus? specialStatus}) async {
    final lane = ValueNotifier<int>(existing?.lane ?? 1);
    final rt = TextEditingController(text: existing == null ? '' : existing.reactionTime.toString());
    final et = TextEditingController(text: existing == null ? '' : existing.elapsedTime.toString());
    final formKey = GlobalKey<FormState>();
    final isSpecial = specialStatus != null;
    await showDialog(context: context, barrierDismissible: false, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        final reaction = double.tryParse(rt.text) ?? 0;
        final elapsed = double.tryParse(et.text) ?? 0;
        final total = reaction + elapsed;
        final preview = isSpecial ? specialStatus! :
            (total < event.bracketSeconds ? RaceResultStatus.breakout : RaceResultStatus.valid);
        return AlertDialog(
          title: Text(isSpecial ? 'Konfirmasi ${specialStatus!.value}' : 'Konfirmasi Hasil Balap',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(rider.riderName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(valueListenable: lane, builder: (_, value, __) => DropdownButtonFormField<int>(
              value: value, decoration: const InputDecoration(labelText: 'Lane', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 1, child: Text('Lane 01')), DropdownMenuItem(value: 2, child: Text('Lane 02'))],
              onChanged: (v) { if (v != null) lane.value = v; },
            )),
            if (!isSpecial) ...[
              const SizedBox(height: 10),
              _numberField(rt, 'Reaction Time (detik)', () => setDialogState(() {})),
              const SizedBox(height: 10),
              _numberField(et, 'Elapsed Time (detik)', () => setDialogState(() {})),
            ],
            const SizedBox(height: 12),
            _previewRow('Total Time', isSpecial ? '-' : '${total.toStringAsFixed(3)} detik'),
            _previewRow('Status', preview.value, color: _statusColor(preview)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
              onPressed: () async {
                if (!isSpecial && !formKey.currentState!.validate()) return;
                await _save(event, rider, lane.value, rt, et, specialStatus);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      });
    });
    rt.dispose();
    et.dispose();
  }

  Future<void> _save(EventModel event, EventRegistrationModel rider, int lane,
      TextEditingController rt, TextEditingController et, RaceResultStatus? special) async {
    setState(() => _processing = true);
    try {
      if (special == RaceResultStatus.jumpStart) {
        await _telemetryService.saveJumpStart(eventId: event.eventId, registrationId: rider.registrationId, lane: lane);
      } else if (special == RaceResultStatus.dnf) {
        await _telemetryService.saveDnf(eventId: event.eventId, registrationId: rider.registrationId, lane: lane);
      } else {
        await _telemetryService.saveRaceResult(
          eventId: event.eventId, registrationId: rider.registrationId, lane: lane,
          reactionTime: double.parse(rt.text), elapsedTime: double.parse(et.text),
          bracketSeconds: event.bracketSeconds,
        );
      }
      _message('Hasil balap berhasil disimpan.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Widget _numberField(TextEditingController controller, String label, VoidCallback changed) => TextFormField(
    controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    validator: (value) => double.tryParse(value ?? '') == null || double.parse(value!) < 0 ? 'Masukkan angka valid' : null,
    onChanged: (_) => changed(),
  );

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 18, color: AppColors.primaryMaroon), const SizedBox(width: 7),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark))]),
      const SizedBox(height: 12), child,
      if (title == 'PESERTA SIAP BALAP') ...[
        const Divider(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _processing || _selectedEventId == null ? null : () {
            final eventId = _selectedEventId!;
            _eventService.getEventsStream().first.then((events) {
              final event = events.firstWhere((e) => e.eventId == eventId);
              _openInput(event);
            });
          }, icon: const Icon(Icons.timer_outlined, size: 16), label: const Text('Input Waktu'))),
          const SizedBox(width: 8),
          PopupMenuButton<RaceResultStatus>(onSelected: (status) {
            _eventService.getEventsStream().first.then((events) {
              final event = events.firstWhere((e) => e.eventId == _selectedEventId);
              _openInput(event, specialStatus: status);
            });
          }, itemBuilder: (_) => const [
            PopupMenuItem(value: RaceResultStatus.jumpStart, child: Text('JUMP_START')),
            PopupMenuItem(value: RaceResultStatus.dnf, child: Text('DNF')),
          ], child: const Icon(Icons.more_vert)),
        ]),
      ],
    ]),
  );

  Widget _previewRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color ?? AppColors.textDark))]),
  );

  Widget _emptyCard(String text) => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)));

  Widget _emptyInside(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)));

  Color _statusColor(RaceResultStatus status) => switch (status) {
    RaceResultStatus.valid => Colors.green.shade700,
    RaceResultStatus.breakout => Colors.orange.shade800,
    RaceResultStatus.jumpStart => Colors.red.shade700,
    RaceResultStatus.dnf => Colors.red.shade900,
  };

  IconData _statusIcon(RaceResultStatus status) => status == RaceResultStatus.valid
      ? Icons.check_circle : Icons.warning_rounded;
}
