import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserModel> registerMember({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Auth created no user for this registration.');
    }

    final profile = UserModel(
      uid: user.uid,
      email: user.email ?? email.trim(),
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      role: UserRole.member,
    );

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toFirestore());
    } on Object catch (error, stackTrace) {
      try {
        await user.delete();
      } on Object catch (rollbackError) {
        throw RegistrationProfileCleanupException(error, rollbackError);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    return profile;
  }

  Stream<UserModel?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserModel.fromMap(data);
    });
  }
}

class RegistrationProfileCleanupException implements Exception {
  const RegistrationProfileCleanupException(
    this.profileError,
    this.rollbackError,
  );

  final Object profileError;
  final Object rollbackError;

  @override
  String toString() {
    return 'Profile creation failed ($profileError), and deleting the '
        'new Auth user also failed ($rollbackError).';
  }
}
