import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Layanan Verifikasi Kehadiran QR & Absensi Paddock (Milik Alfa / Sekretaris)
/// Sesuai PRD v1.4: Hanya peserta lunas yang bisa hadir, dan ada aksi "Tutup Verifikasi Kehadiran".
class AttendanceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AttendanceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _regCollection =>
      _firestore.collection('event_registrations');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Stream daftar peserta lunas untuk event tertentu
  Stream<List<Map<String, dynamic>>> getPaidRegistrationsStream(String eventId) {
    return _regCollection
        .where('eventId', isEqualTo: eventId)
        .where('paymentStatus', isEqualTo: 'PAID')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['registrationId'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Verifikasi kehadiran rider setelah scan QR Code
  Future<void> checkInRider(String registrationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Petugas harus login terlebih dahulu.');
    }

    final docRef = _regCollection.doc(registrationId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Data pendaftaran tidak ditemukan.');
    }

    final data = doc.data()!;
    if (data['paymentStatus'] != 'PAID') {
      throw Exception('Pembalap belum menyelesaikan pembayaran pendaftaran.');
    }

    if (data['attendanceStatus'] == 'PRESENT') {
      throw Exception('Pembalap sudah tercatat HADIR sebelumnya.');
    }

    if (data['attendanceStatus'] == 'ABSENT') {
      throw Exception('Pendaftaran pembalap telah dicoret karena kehadiran sudah ditutup.');
    }

    await docRef.update({
      'attendanceStatus': 'PRESENT',
      'attendanceCheckedBy': currentUser.uid,
      'attendanceCheckedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Aksi "Tutup Verifikasi Kehadiran" (PRD v1.4):
  /// Peserta lunas yang belum hadir (PENDING) otomatis diubah menjadi ABSENT (dicoret).
  /// Menandai field `attendanceClosedAt` pada dokumen event.
  Future<int> closeAttendance(String eventId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Petugas harus login.');
    }

    // Ambil peserta lunas yang belum hadir
    final query = await _regCollection
        .where('eventId', isEqualTo: eventId)
        .where('paymentStatus', isEqualTo: 'PAID')
        .where('attendanceStatus', isEqualTo: 'PENDING')
        .get();

    final batch = _firestore.batch();

    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'attendanceStatus': 'ABSENT',
        'attendanceCheckedBy': currentUser.uid,
        'attendanceCheckedAt': FieldValue.serverTimestamp(),
      });
    }

    // Catat waktu penutupan kehadiran pada event
    final eventRef = _eventsCollection.doc(eventId);
    batch.update(eventRef, {
      'attendanceClosedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return query.docs.length;
  }
}

