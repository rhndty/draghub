import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/event_registration_model.dart';
import '../models/motorcycle_model.dart';

/// Layanan Pendaftaran Event & Status Rider (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Mendaftar event dengan motor yang cocok (tipe & batas piston)
/// - Format ID pendaftaran: eventId_userId (Satu rider satu pendaftaran per event)
/// - Unggah & unggah ulang bukti transfer
/// - Stream pendaftaran saya & kartu balap
class RegistrationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RegistrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _regCollection =>
      _firestore.collection('event_registrations');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Mendaftarkan rider ke event balap resmi
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

    // 1. Validasi Status Event & Kuota
    if (event.status != 'PUBLISHED') {
      throw Exception('Pendaftaran ditutup karena status event bukan PUBLISHED.');
    }

    if (event.remainingQuota <= 0) {
      throw Exception('Maaf, kuota peserta untuk event ini sudah penuh.');
    }

    // 2. Validasi Kecocokan Motor (PRD 3.1)
    final eventVehicleType = VehicleType.fromValue(event.vehicleType.toUpperCase());
    if (!bike.isEligibleFor(
      eventVehicleType: eventVehicleType,
      maxPistonDiameterMm: event.maxPistonDiameterMm,
    )) {
      throw Exception(
        'Motor tidak memenuhi regulasi kelas event (${event.className}). '
        'Pastikan tipe transmisi sama dan piston <= ${event.maxPistonDiameterMm}mm.',
      );
    }

    // 3. Validasi Satu Rider Satu Pendaftaran per Event (ERD 1 & PRD 3.1)
    final registrationId = '${event.eventId}_${currentUser.uid}';
    final existingDoc = await _regCollection.doc(registrationId).get();

    if (existingDoc.exists) {
      final existingData = existingDoc.data();
      final status = existingData?['paymentStatus'];
      if (status != 'REJECTED') {
        throw Exception('Anda sudah mendaftar pada event ini.');
      }
    }

    // 4. Buat Model Registrasi
    final registration = EventRegistrationModel(
      registrationId: registrationId,
      eventId: event.eventId,
      userId: currentUser.uid,
      bikeId: bike.bikeId,
      riderName: riderName.trim().isEmpty ? (currentUser.displayName ?? 'Rider') : riderName.trim(),
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

  /// Mengunggah ulang bukti transfer jika sebelumnya DITOLAK oleh Bendahara (PRD 4.3)
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
      throw Exception('Anda tidak memiliki hak mengubah pendaftaran ini.');
    }

    if (data['paymentStatus'] != 'REJECTED') {
      throw Exception('Unggah ulang bukti hanya bisa dilakukan pada pendaftaran yang DITOLAK.');
    }

    // Cek apakah event masih PUBLISHED
    final eventDoc = await _eventsCollection.doc(data['eventId']).get();
    if (eventDoc.exists && eventDoc.data()?['status'] != 'PUBLISHED') {
      throw Exception('Event sudah tidak menerima verifikasi bukti pembayaran.');
    }

    await docRef.update({
      'paymentProofUrl': newPaymentProofUrl.trim(),
      'paymentStatus': PaymentStatus.pending.value,
      'paymentRejectionReason': null,
      'registeredAt': Timestamp.now(),
    });
  }

  /// Mendengarkan stream semua pendaftaran milik user yang sedang login
  Stream<List<EventRegistrationModel>> getMyRegistrationsStream({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _regCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = <EventRegistrationModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(EventRegistrationModel.fromMap(doc.data(), documentId: doc.id));
        } catch (_) {
          // Abaikan dokumen corrupt jika ada
        }
      }

      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  /// Mendengarkan stream pendaftaran untuk satu event tertentu
  Stream<EventRegistrationModel?> getRegistrationForEventStream({
    required String eventId,
    String? userId,
  }) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

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

