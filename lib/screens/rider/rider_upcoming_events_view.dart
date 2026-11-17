import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../models/event_registration_model.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../theme/app_colors.dart';
import 'register_event_dialog.dart';

/// Tab Tampilan Event Mendatang & Pendaftaran Rider (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Mengambil event berstatus 'PUBLISHED'
/// - Menampilkan sisa kuota (quota - registeredCount)
/// - Menampilkan tombol pendaftaran balap jika kuota tersedia
class RiderUpcomingEventsView extends StatefulWidget {
  const RiderUpcomingEventsView({super.key});

  @override
  State<RiderUpcomingEventsView> createState() => _RiderUpcomingEventsViewState();
}

class _RiderUpcomingEventsViewState extends State<RiderUpcomingEventsView> {
  final EventService _eventService = EventService();
  final RegistrationService _registrationService = RegistrationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getPublishedEventsStream(),
      builder: (context, eventSnapshot) {
        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            ),
          );
        }

        final events = eventSnapshot.data ?? [];
        if (events.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Belum Ada Event Mendatang',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Agenda kejuaraan balap drag resmi akan tampil di sini saat disetujui Ketua.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Ambil stream pendaftaran saya agar kita tahu event mana yang sudah didaftari
        return StreamBuilder<List<EventRegistrationModel>>(
          stream: _registrationService.getMyRegistrationsStream(userId: _uid),
          builder: (context, regSnapshot) {
            final myRegistrations = regSnapshot.data ?? [];
            final registeredEventIds = myRegistrations.map((r) => r.eventId).toSet();

            return Column(
              children: events.map((event) {
                final isRegistered = registeredEventIds.contains(event.eventId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildEventCard(event, isRegistered),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event, bool isRegistered) {
    final day = event.eventDate.day.toString();
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    final monthStr = months[event.eventDate.month - 1];
    final isFull = event.remainingQuota <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Poster
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.imageUrl.isNotEmpty
                      ? event.imageUrl
                      : 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.two_wheeler, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          color: isFull ? Colors.red : AppColors.primaryMaroon,
                          size: 8),
                      const SizedBox(width: 4),
                      Text(
                        isFull ? 'KUOTA PENUH' : 'PENDAFTARAN BUKA',
                        style: TextStyle(
                          color: isFull ? Colors.white : AppColors.primaryMaroon,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.vehicleType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Baris Statistik Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.calendar_month, '$day $monthStr', 'TANGGAL'),
                _buildStatItem(Icons.payments_outlined, 'Rp ${event.registrationFee}', 'BIAYA DAFTAR',
                    valueColor: AppColors.primaryMaroon),
                _buildStatItem(Icons.group_outlined, '${event.remainingQuota} SLOT', 'SISA KUOTA',
                    valueColor: isFull ? Colors.red : Colors.green.shade700),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Label Kelas Balap
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'KELAS: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      '${event.className} • Maks. Piston ${event.maxPistonDiameterMm.toStringAsFixed(0)}mm',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Aksi Pendaftaran
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isRegistered || isFull
                          ? null
                          : () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => RegisterEventDialog(event: event),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        isRegistered
                            ? 'SUDAH MENDAFTAR'
                            : isFull
                                ? 'KUOTA HABIS'
                                : 'DAFTAR SEKARANG',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _showClassRulesDialog(event),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'REGULASI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {Color valueColor = AppColors.textDark}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryMaroon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
      ],
    );
  }

  void _showClassRulesDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rule, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            const Text('REGULASI KELAS BALAP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
            const SizedBox(height: 12),
            _buildRuleRow('Tipe Kendaraan', event.vehicleType),
            _buildRuleRow('Batas Maksimal Piston', '${event.maxPistonDiameterMm.toStringAsFixed(0)} mm'),
            _buildRuleRow('Braket Waktu', '${event.bracketSeconds.toStringAsFixed(0)} Detik'),
            _buildRuleRow('Kuota Peserta', '${event.quota} Starter'),
            _buildRuleRow('Biaya Pendaftaran', 'Rp ${event.registrationFee}'),
            const SizedBox(height: 12),
            const Text(
              '* Inspeksi Paddock (Scrutineering) dilakukan sebelum balap. Piston yang melebihi batas ketentuan otomatis DISKUALIFIKASI tanpa pengembalian biaya pendaftaran.',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('TUTUP', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

