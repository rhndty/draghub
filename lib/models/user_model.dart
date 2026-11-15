import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  member('anggota'),
  president('ketua'),
  vicePresident('wakil'),
  secretary('sekretaris'),
  treasurer('bendahara');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw FormatException('Unknown user role: $value'),
    );
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final DateTime? createdAt;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: _requiredString(map, 'uid'),
      email: _requiredString(map, 'email'),
      fullName: _requiredString(map, 'fullName'),
      phoneNumber: _requiredString(map, 'phoneNumber'),
      role: UserRole.fromValue(_requiredString(map, 'role')),
      createdAt: _dateTimeOrNull(map['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'role': role.value,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid "$field" in user document.');
    }
    return value;
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw const FormatException('Invalid "createdAt" in user document.');
  }
}
