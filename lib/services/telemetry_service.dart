import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_registration_model.dart';
import '../models/race_result_model.dart';

/// Service pencatatan hasil waktu balap.
///
/// Tanggung jawab:
/// - Mengambil peserta yang berhak mengikuti balapan.
/// - Menghitung total waktu.
/// - Menentukan status VALID atau BREAKOUT.
/// - Menyimpan status JUMP_START dan DNF.
/// - Mengubah hasil selama event masih ONGOING.
/// - Menolak pencatatan ketika event sudah COMPLETED.
class TelemetryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TelemetryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      _firestore.collection('event_registrations');

  CollectionReference<Map<String, dynamic>> get _resultsCollection =>
      _firestore.collection('race_results');

  /// Mengambil peserta yang memenuhi syarat untuk dicatat hasil balapnya:
  /// - Pembayaran PAID
  /// - Kehadiran PRESENT
  /// - Scrutineering PASSED
  Stream<List<EventRegistrationModel>> getEligibleRegistrationsStream(
    String eventId,
  ) {
    return _registrationsCollection
        .where('eventId', isEqualTo: eventId)
        .where('paymentStatus', isEqualTo: PaymentStatus.paid.value)
        .where('attendanceStatus', isEqualTo: AttendanceStatus.present.value)
        .where(
          'scrutineeringStatus',
          isEqualTo: ScrutineeringStatus.passed.value,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return EventRegistrationModel.fromMap(
              doc.data(),
              documentId: doc.id,
            );
          }).toList(),
        );
  }

  /// Mengambil semua hasil balap dari satu event.
  Stream<List<RaceResultModel>> getResultsStream(String eventId) {
    return _resultsCollection
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return RaceResultModel.fromFirestore(doc);
          }).toList(),
        );
  }

  /// Mengambil satu hasil balap berdasarkan registrationId.
  Future<RaceResultModel?> getResult(String registrationId) async {
    final doc = await _resultsCollection.doc(registrationId).get();

    if (!doc.exists) {
      return null;
    }

    return RaceResultModel.fromFirestore(doc);
  }

  /// Mengambil data peserta berdasarkan ID pendaftaran.
  /// Dipakai UI riwayat telemetri agar yang ditampilkan adalah nama rider,
  /// bukan registrationId.
  Future<EventRegistrationModel?> getRegistration(
    String registrationId,
  ) async {
    final doc = await _registrationsCollection.doc(registrationId).get();

    if (!doc.exists) {
      return null;
    }

    return EventRegistrationModel.fromMap(
      doc.data()!,
      documentId: doc.id,
    );
  }

  /// Menyimpan atau memperbarui hasil VALID/BREAKOUT.
  ///
  /// BREAKOUT otomatis jika totalTime lebih cepat dari braket.
  Future<RaceResultModel> saveRaceResult({
    required String eventId,
    required String registrationId,
    required int lane,
    required double reactionTime,
    required double elapsedTime,
    required double bracketSeconds,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Ofisial harus login terlebih dahulu.');
    }

    _validateLane(lane);
    _validateTime(reactionTime, 'Reaction time');
    _validateTime(elapsedTime, 'Elapsed time');
    _validateTime(bracketSeconds, 'Bracket');

    await _validateEventIsOngoing(eventId);
    await _validateRegistration(
      eventId: eventId,
      registrationId: registrationId,
    );

    final totalTime = reactionTime + elapsedTime;

    final status = totalTime < bracketSeconds
        ? RaceResultStatus.breakout
        : RaceResultStatus.valid;

    final resultRef = _resultsCollection.doc(registrationId);
    final existingResult = await resultRef.get();
    final now = DateTime.now();

    final result = RaceResultModel(
      resultId: registrationId,
      eventId: eventId,
      registrationId: registrationId,
      lane: lane,
      reactionTime: reactionTime,
      elapsedTime: elapsedTime,
      totalTime: totalTime,
      status: status,
      recordedBy: existingResult.exists
          ? _readRecordedBy(existingResult.data())
          : currentUser.uid,
      recordedAt: existingResult.exists
          ? _readRecordedAt(existingResult.data()) ?? now
          : now,
      updatedAt: existingResult.exists ? now : null,
    );

    await resultRef.set(
      result.toFirestore(),
      SetOptions(merge: false),
    );

    return result;
  }

  /// Menyimpan hasil JUMP_START.
  Future<RaceResultModel> saveJumpStart({
    required String eventId,
    required String registrationId,
    required int lane,
    double reactionTime = 0,
    double elapsedTime = 0,
  }) async {
    return _saveSpecialResult(
      eventId: eventId,
      registrationId: registrationId,
      lane: lane,
      reactionTime: reactionTime,
      elapsedTime: elapsedTime,
      status: RaceResultStatus.jumpStart,
    );
  }

  /// Menyimpan hasil DNF.
  Future<RaceResultModel> saveDnf({
    required String eventId,
    required String registrationId,
    required int lane,
    double reactionTime = 0,
    double elapsedTime = 0,
  }) async {
    return _saveSpecialResult(
      eventId: eventId,
      registrationId: registrationId,
      lane: lane,
      reactionTime: reactionTime,
      elapsedTime: elapsedTime,
      status: RaceResultStatus.dnf,
    );
  }

  Future<RaceResultModel> _saveSpecialResult({
    required String eventId,
    required String registrationId,
    required int lane,
    required double reactionTime,
    required double elapsedTime,
    required RaceResultStatus status,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Ofisial harus login terlebih dahulu.');
    }

    _validateLane(lane);
    _validateTime(reactionTime, 'Reaction time');
    _validateTime(elapsedTime, 'Elapsed time');

    await _validateEventIsOngoing(eventId);
    await _validateRegistration(
      eventId: eventId,
      registrationId: registrationId,
    );

    final resultRef = _resultsCollection.doc(registrationId);
    final existingResult = await resultRef.get();
    final now = DateTime.now();

    final result = RaceResultModel(
      resultId: registrationId,
      eventId: eventId,
      registrationId: registrationId,
      lane: lane,
      reactionTime: reactionTime,
      elapsedTime: elapsedTime,
      totalTime: reactionTime + elapsedTime,
      status: status,
      recordedBy: existingResult.exists
          ? _readRecordedBy(existingResult.data())
          : currentUser.uid,
      recordedAt: existingResult.exists
          ? _readRecordedAt(existingResult.data()) ?? now
          : now,
      updatedAt: existingResult.exists ? now : null,
    );

    await resultRef.set(
      result.toFirestore(),
      SetOptions(merge: false),
    );

    return result;
  }

  /// Memastikan event masih dapat menerima hasil balapan.
  Future<void> _validateEventIsOngoing(String eventId) async {
    final eventDoc = await _eventsCollection.doc(eventId).get();

    if (!eventDoc.exists) {
      throw Exception('Event tidak ditemukan.');
    }

    final data = eventDoc.data()!;
    final status = data['status']?.toString().toUpperCase();

    if (status != 'ONGOING') {
      if (status == 'COMPLETED') {
        throw Exception(
          'Event sudah selesai. Hasil balapan tidak dapat diubah.',
        );
      }

      throw Exception(
        'Hasil balapan hanya dapat dicatat saat event berstatus ONGOING.',
      );
    }
  }

  /// Memastikan peserta valid dan sudah memenuhi seluruh persyaratan.
  Future<void> _validateRegistration({
    required String eventId,
    required String registrationId,
  }) async {
    final registrationDoc =
        await _registrationsCollection.doc(registrationId).get();

    if (!registrationDoc.exists) {
      throw Exception('Data pendaftaran tidak ditemukan.');
    }

    final data = registrationDoc.data()!;

    if (data['eventId'] != eventId) {
      throw Exception('Peserta bukan bagian dari event ini.');
    }

    if (data['paymentStatus'] != PaymentStatus.paid.value) {
      throw Exception('Peserta belum berstatus PAID.');
    }

    if (data['attendanceStatus'] != AttendanceStatus.present.value) {
      throw Exception('Peserta belum terverifikasi hadir.');
    }

    if (data['scrutineeringStatus'] != ScrutineeringStatus.passed.value) {
      throw Exception('Peserta belum lolos scrutineering.');
    }
  }

  static void _validateLane(int lane) {
    if (lane != 1 && lane != 2) {
      throw Exception('Lane hanya boleh bernilai 1 atau 2.');
    }
  }

  static void _validateTime(double value, String fieldName) {
    if (value.isNaN || value.isInfinite || value < 0) {
      throw Exception('$fieldName harus berupa angka positif.');
    }
  }

  static String _readRecordedBy(Map<String, dynamic>? data) {
    final value = data?['recordedBy'];

    if (value is String && value.isNotEmpty) {
      return value;
    }

    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  static DateTime? _readRecordedAt(Map<String, dynamic>? data) {
    final value = data?['recordedAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
