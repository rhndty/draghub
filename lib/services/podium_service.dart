import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/race_result_model.dart';

/// Service perhitungan dan penyimpanan snapshot podium.
///
/// Service ini hanya menghitung podium. Perubahan status event menjadi
/// COMPLETED tetap dilakukan oleh EventStatusService milik Rafli.
class PodiumService {
  final FirebaseFirestore _firestore;

  PodiumService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _resultsCollection =>
      _firestore.collection('race_results');

  CollectionReference<Map<String, dynamic>> get _registrationsCollection =>
      _firestore.collection('event_registrations');

  /// Menghitung podium dari hasil VALID sebuah event.
  ///
  /// Urutan:
  /// 1. totalTime terkecil.
  /// 2. Jika sama, reactionTime terkecil.
  ///
  /// BREAKOUT, JUMP_START, dan DNF otomatis tidak ikut.
  ///
  /// Normalnya dipanggil saat event masih `ONGOING` (sebelum "Akhiri Event").
  /// Set `allowCompleted: true` hanya untuk menghitung ulang snapshot podium
  /// pada event yang sudah `COMPLETED` (mis. perbaikan data lama).
  Future<List<Map<String, dynamic>>> calculatePodium(
    String eventId, {
    bool allowCompleted = false,
  }) async {
    final eventSnapshot = await _eventsCollection.doc(eventId).get();

    if (!eventSnapshot.exists) {
      throw StateError('Event tidak ditemukan.');
    }

    final eventData = eventSnapshot.data()!;
    final status = eventData['status']?.toString().toUpperCase();
    final canCalculate =
        status == 'ONGOING' || (allowCompleted && status == 'COMPLETED');
    if (!canCalculate) {
      throw StateError(
        'Podium hanya dapat dihitung saat event berstatus ONGOING.',
      );
    }

    final resultSnapshot = await _resultsCollection
        .where('eventId', isEqualTo: eventId)
        .get();

    final results = <RaceResultModel>[];
    for (final doc in resultSnapshot.docs) {
      final result = RaceResultModel.fromFirestore(doc);
      if (result.isEligibleForPodium) {
        results.add(result);
      }
    }

    results.sort((a, b) {
      final totalComparison = a.totalTime.compareTo(b.totalTime);
      if (totalComparison != 0) return totalComparison;
      return a.reactionTime.compareTo(b.reactionTime);
    });

    final podium = <Map<String, dynamic>>[];
    for (var index = 0; index < results.length && index < 3; index++) {
      final result = results[index];
      final registration = await _registrationsCollection
          .doc(result.registrationId)
          .get();

      if (!registration.exists) {
        throw StateError(
          'Data pendaftaran ${result.registrationId} tidak ditemukan.',
        );
      }

      final registrationData = registration.data()!;
      podium.add({
        'rank': index + 1,
        'registrationId': result.registrationId,
        'riderName': registrationData['riderName'] ?? 'Pembalap',
        'startNumber': registrationData['assignedStartNumber'] ?? '-',
        'bikeName': registrationData['bikeName'] ?? 'Motor Balap',
        'lane': result.lane,
        'reactionTime': result.reactionTime,
        'elapsedTime': result.elapsedTime,
        'totalTime': result.totalTime,
        'status': result.status.value,
      });
    }

    return podium;
  }

  /// Menghitung podium lalu menyimpan snapshot ke events/{eventId}.podium.
  ///
  /// Method ini tidak mengubah status event. Setelah method ini selesai,
  /// caller dapat meneruskan snapshot ke EventStatusService.completeEvent().
  Future<List<Map<String, dynamic>>> calculateAndSavePodium(
    String eventId, {
    bool allowCompleted = false,
  }) async {
    final podium = await calculatePodium(
      eventId,
      allowCompleted: allowCompleted,
    );

    await _eventsCollection.doc(eventId).update({
      'podium': podium,
      'podiumCalculatedAt': FieldValue.serverTimestamp(),
    });

    return podium;
  }

  /// Membaca snapshot podium yang sudah tersimpan pada event.
  Stream<List<Map<String, dynamic>>> getPodiumStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final podium = data?['podium'];

      if (podium is! List) return <Map<String, dynamic>>[];

      return podium
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    });
  }
}
