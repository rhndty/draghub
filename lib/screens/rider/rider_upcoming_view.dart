import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/event_model.dart';
import '../../models/event_registration_model.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/event_card.dart';
import 'register_event_modal.dart';

/// Tab UPCOMING / MENDATANG (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4, ERD v1.4, & Pembagian Tugas GitFlow v1.4:
/// - Menampilkan daftar kejuaraan balap resmi dengan status 'PUBLISHED'
/// - Menggunakan EventCard bersama milik Alfa (widgets/event_card.dart)
/// - Menampilkan sisa kuota dinamis (quota - registeredCount)
/// - Membuka modal pendaftaran (RegisterEventModal) dengan filter motor & upload bukti transfer
/// - Menandai event yang sudah didaftari oleh rider ('SUDAH TERDAFTAR')
class RiderUpcomingView extends StatefulWidget {
  final VoidCallback? onSwitchToOngoing;

  const RiderUpcomingView({super.key, this.onSwitchToOngoing});

  @override
  State<RiderUpcomingView> createState() => _RiderUpcomingViewState();
}

class _RiderUpcomingViewState extends State<RiderUpcomingView> {
  final EventService _eventService = EventService();
  final RegistrationService _registrationService = RegistrationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  void _openRegistrationModal(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegisterEventModal(event: event),
    );
  }

  void _showAlreadyRegisteredNotice(EventModel event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Anda sudah mendaftar di "${event.title}". Cek tiket & paddock pass Anda di tab ONGOING.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        action: widget.onSwitchToOngoing != null
            ? SnackBarAction(
                label: 'LIHAT TIKET',
                textColor: Colors.amber,
                onPressed: widget.onSwitchToOngoing!,
              )
            : null,
        backgroundColor: AppColors.primaryMaroon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER SECTION
        Row(
          children: const [
            Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primaryMaroon,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'KEJUARAAN RESMI MENDATANG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih kejuaraan resmi untuk mendaftarkan motor balap Anda sesuai kelas dan batas diameter piston.',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // 2. STREAM DAFTAR EVENT PUBLISHED
        StreamBuilder<List<EventModel>>(
          stream: _eventService.getPublishedEventsStream(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryMaroon,
                  ),
                ),
              );
            }

            final publishedEvents = eventSnapshot.data ?? [];

            if (publishedEvents.isEmpty) {
              return _buildEmptyEventsState();
            }

            // STREAM PENDAFTARAN SAYA UNTUK CEK STATUS TERDAFTAR
            return StreamBuilder<List<EventRegistrationModel>>(
              stream: _registrationService.getMyRegistrationsStream(
                userId: _uid,
              ),
              builder: (context, regSnapshot) {
                final myRegistrations = regSnapshot.data ?? [];
                final registeredEventIds = <String>{};

                for (final reg in myRegistrations) {
                  // Jika statusnya bukan REJECTED, berarti pendaftaran aktif/pending/lunas
                  if (reg.paymentStatus != PaymentStatus.rejected) {
                    registeredEventIds.add(reg.eventId);
                  }
                }

                return Column(
                  children: publishedEvents.map((event) {
                    final bool isAlreadyRegistered = registeredEventIds
                        .contains(event.eventId);
                    final bool isQuotaFull = event.remainingQuota <= 0;

                    String? actionText;
                    VoidCallback? actionCallback;

                    if (isAlreadyRegistered) {
                      actionText = 'SUDAH TERDAFTAR';
                      actionCallback = () =>
                          _showAlreadyRegisteredNotice(event);
                    } else if (isQuotaFull) {
                      actionText = 'KUOTA PENUH';
                      actionCallback = null;
                    } else {
                      actionText = 'DAFTAR SEKARANG';
                      actionCallback = () => _openRegistrationModal(event);
                    }

                    return EventCard(
                      event: event,
                      actionButtonText: actionText,
                      onActionButtonPressed: actionCallback,
                      onTap: () {
                        if (isAlreadyRegistered) {
                          _showAlreadyRegisteredNotice(event);
                        } else if (!isQuotaFull) {
                          _openRegistrationModal(event);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyEventsState() {
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
          Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 14),
          Text(
            'Belum Ada Kejuaraan Terbuka',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Panitia sekretariat belum merilis jadwal pendaftaran event balap baru. Silakan pantau berkala untuk kejuaraan resmi mendatang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
