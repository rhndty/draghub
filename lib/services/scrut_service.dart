import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Layanan Inspeksi Scrutineering Mesin Sebelum Balap (Milik Alfa / Sekretaris)
/// Sesuai PRD v1.4: Piston <= batas -> PASSED. Piston > batas -> DISQUALIFIED (alasan wajib, tanpa toleransi).
class ScrutService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ScrutService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _regCollection =>
      _firestore.collection('event_registrations');

  /// Stream peserta yang berhak discrutineering:
  /// Yaitu yang sudah LUNAS (PAID) dan sudah HADIR (PRESENT) di paddock
  Stream<List<Map<String, dynamic>>> getScrutQueueStream(String eventId) {
    return _regCollection
        .where('eventId', isEqualTo: eventId)
        .where('paymentStatus', isEqualTo: 'PAID')
        .where('attendanceStatus', isEqualTo: 'PRESENT')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['registrationId'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Memproses hasil pengukuran piston jangka sorong:
  /// - Lolos jika measuredPistonMm <= maxPistonDiameterMm
  /// - Diskualifikasi jika measuredPistonMm > maxPistonDiameterMm (wajib menyertakan alasan)
  Future<void> submitScrutResult({
    required String registrationId,
    required double measuredPistonMm,
    required double maxPistonDiameterMm,
    String? disqualificationReason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Petugas scrutineering harus login.');
    }

    final bool isPassed = measuredPistonMm <= maxPistonDiameterMm;

    if (!isPassed && (disqualificationReason == null || disqualificationReason.trim().isEmpty)) {
      throw Exception('Alasan diskualifikasi wajib diisi untuk motor overspec.');
    }

    final docRef = _regCollection.doc(registrationId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Data pendaftaran tidak ditemukan.');
    }

    final historyItem = {
      'timestamp': Timestamp.now(),
      'officerUid': currentUser.uid,
      'measuredPistonMm': measuredPistonMm,
      'status': isPassed ? 'PASSED' : 'DISQUALIFIED',
      'reason': isPassed ? 'Sesuai regulasi kelas' : disqualificationReason!.trim(),
    };

    await docRef.update({
      'measuredPistonMm': measuredPistonMm,
      'scrutineeringStatus': isPassed ? 'PASSED' : 'DISQUALIFIED',
      'disqualificationReason': isPassed ? null : disqualificationReason!.trim(),
      'scrutineeredBy': currentUser.uid,
      'scrutineeredAt': FieldValue.serverTimestamp(),
      'scrutineeringHistory': FieldValue.arrayUnion([historyItem]),
    });
  }
}

