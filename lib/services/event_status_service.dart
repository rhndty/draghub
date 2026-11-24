import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class EventStatusService {
  EventStatusService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> approveDraft(String eventId) {
    return _changeDraftStatus(
      eventId: eventId,
      nextStatus: 'PUBLISHED',
      setApprover: true,
    );
  }

  Future<void> rejectDraft(String eventId) {
    return _changeDraftStatus(
      eventId: eventId,
      nextStatus: 'REJECTED',
      setApprover: false,
    );
  }

  Future<void> startEvent(String eventId) async {
    await _runManagerTransition(
      eventId: eventId,
      expectedStatus: 'PUBLISHED',
      update: {'status': 'ONGOING'},
    );
  }

  Future<void> completeEvent({
    required String eventId,
    required List<Map<String, dynamic>> podium,
  }) async {
    if (podium.length > 3) {
      throw ArgumentError.value(podium.length, 'podium.length', 'Must be <= 3');
    }

    await _runManagerTransition(
      eventId: eventId,
      expectedStatus: 'ONGOING',
      update: {
        'status': 'COMPLETED',
        'podium': podium,
        'podiumCalculatedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _changeDraftStatus({
    required String eventId,
    required String nextStatus,
    required bool setApprover,
  }) async {
    await _runManagerTransition(
      eventId: eventId,
      expectedStatus: 'DRAFT',
      update: {
        'status': nextStatus,
        if (setApprover) 'approvedBy': _currentUid,
      },
    );
  }

  Future<void> _runManagerTransition({
    required String eventId,
    required String expectedStatus,
    required Map<String, Object?> update,
  }) async {
    final uid = _currentUid;
    final userRef = _firestore.collection('users').doc(uid);
    final eventRef = _firestore.collection('events').doc(eventId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final eventSnapshot = await transaction.get(eventRef);

      if (!userSnapshot.exists) {
        throw StateError('Profil pengguna tidak ditemukan.');
      }

      final role = UserRole.fromValue(
        (userSnapshot.data()?['role'] as String?) ?? '',
      );
      if (role != UserRole.president && role != UserRole.vicePresident) {
        throw StateError('Aksi ini hanya dapat dilakukan Ketua atau Wakil.');
      }

      if (!eventSnapshot.exists) {
        throw StateError('Event tidak ditemukan.');
      }
      if (eventSnapshot.data()?['status'] != expectedStatus) {
        throw StateError(
          'Status event berubah. Muat ulang sebelum mencoba lagi.',
        );
      }

      transaction.update(eventRef, update);
    });
  }

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sesi pengguna berakhir. Silakan masuk kembali.');
    }
    return uid;
  }
}
