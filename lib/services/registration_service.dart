import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';
import '../models/event_registration_model.dart';
import '../models/motorcycle_model.dart';

/// Layanan Pendaftaran Event & Status Tiket Balap Rider (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 (Bab 4.3 & 4.4) & ERD v1.4 (Bab 2.4 & 3.1):
/// - Koleksi root Firestore: 'event_registrations'
/// - Format ID Dokumen: {eventId}_{userId} (mencegah pendaftaran ganda pada event yang sama)
/// - Mengunggah bukti transfer struk pembayaran ke Cloudinary
/// - Unggah ulang bukti transfer jika berstatus 'REJECTED'
/// - Pemantauan status pendaftaran, kehadiran, dan scrutineering
class RegistrationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RegistrationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _regCollection =>
      _firestore.collection('event_registrations');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Mendaftarkan motor dan pembalap ke event balap resmi (PRD 3.1 & 4.3)
  Future<String> registerForEvent({
    required EventModel event,
    required MotorcycleModel bike,
    required String paymentProofUrl,
    required String riderName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Rider harus login terlebih dahulu.');
    }

    // 1. Validasi Status Event & Ketersediaan Kuota (PRD 4.4)
    if (event.status != 'PUBLISHED') {
      throw Exception(
        'Pendaftaran ditutup karena status event bukan PUBLISHED.',
      );
    }

    if (event.remainingQuota <= 0) {
      throw Exception('Maaf, kuota peserta untuk kejuaraan ini sudah penuh.');
    }

    // 2. Validasi Regulasi Kelas & Kecocokan Mesin (PRD 3.1)
    final eventVehicleType = VehicleType.fromValue(
      event.vehicleType.toUpperCase(),
    );
    if (!bike.isEligibleFor(
      eventVehicleType: eventVehicleType,
      maxPistonDiameterMm: event.maxPistonDiameterMm,
    )) {
      throw Exception(
        'Motor tidak memenuhi regulasi kelas event (${event.className}). '
        'Pastikan tipe transmisi sama dan piston motor <= ${event.maxPistonDiameterMm.toStringAsFixed(0)}mm.',
      );
    }

    // 3. Validasi Batasan Satu Rider Satu Pendaftaran per Event (ERD 2.4 & 3.1)
    final registrationId = '${event.eventId}_${currentUser.uid}';
    final existingDoc = await _regCollection.doc(registrationId).get();

    if (existingDoc.exists) {
      final existingData = existingDoc.data();
      final status = existingData?['paymentStatus'];
      if (status != 'REJECTED') {
        throw Exception('Anda sudah terdaftar pada kejuaraan ini.');
      }
    }

    final finalRiderName = riderName.trim().isEmpty
        ? (currentUser.displayName ?? 'Pembalap')
        : riderName.trim();

    // 4. Inisialisasi Data Pendaftaran Sesuai ERD v1.4
    final registration = EventRegistrationModel(
      registrationId: registrationId,
      eventId: event.eventId,
      userId: currentUser.uid,
      bikeId: bike.bikeId,
      riderName: finalRiderName,
      bikeName: '${bike.brand} ${bike.modelName}',
      vehicleType: bike.vehicleType.value,
      pistonDiameterMm: bike.pistonDiameterMm,
      paymentProofUrl: paymentProofUrl.trim(),
      paymentStatus: PaymentStatus.pending,
      attendanceStatus: AttendanceStatus.pending,
      scrutineeringStatus: ScrutineeringStatus.pending,
      registeredAt: DateTime.now(),
    );

    await _regCollection.doc(registrationId).set(registration.toFirestore());
    return registrationId;
  }

  /// Mengunggah ulang bukti transfer pada pendaftaran yang DITOLAK oleh Bendahara (PRD 4.3 & ERD 3.2)
  Future<void> reuploadPaymentProof({
    required String registrationId,
    required String newPaymentProofUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Rider harus login.');
    }

    final docRef = _regCollection.doc(registrationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Data pendaftaran tidak ditemukan.');
    }

    final data = doc.data()!;
    if (data['userId'] != currentUser.uid) {
      throw Exception(
        'Anda tidak memiliki wewenang untuk mengubah pendaftaran ini.',
      );
    }

    if (data['paymentStatus'] != 'REJECTED') {
      throw Exception(
        'Unggah ulang bukti hanya berlaku untuk pembayaran yang DITOLAK.',
      );
    }

    // Pastikan event masih PUBLISHED (belum ONGOING)
    final eventDoc = await _eventsCollection.doc(data['eventId']).get();
    if (eventDoc.exists && eventDoc.data()?['status'] != 'PUBLISHED') {
      throw Exception(
        'Pendaftaran ditutup karena event sudah dimulai atau selesai.',
      );
    }

    await docRef.update({
      'paymentProofUrl': newPaymentProofUrl.trim(),
      'paymentStatus': PaymentStatus.pending.value,
      'paymentRejectionReason': null,
      'registeredAt': Timestamp.now(),
    });
  }

  /// Mendengarkan stream seluruh tiket pendaftaran milik user yang login
  Stream<List<EventRegistrationModel>> getMyRegistrationsStream({
    String? userId,
  }) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _regCollection.where('userId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final list = <EventRegistrationModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(
            EventRegistrationModel.fromMap(doc.data(), documentId: doc.id),
          );
        } catch (_) {}
      }

      // Urutkan berdasarkan waktu pendaftaran terbaru
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  /// Mengambil data pendaftaran spesifik untuk satu event tertentu
  Stream<EventRegistrationModel?> getMyRegistrationForEventStream(
    String eventId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    final registrationId = '${eventId}_$uid';
    return _regCollection.doc(registrationId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return EventRegistrationModel.fromMap(doc.data()!, documentId: doc.id);
      } catch (_) {
        return null;
      }
    });
  }
}
