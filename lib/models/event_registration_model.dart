import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending('PENDING'),
  paid('PAID'),
  rejected('REJECTED');

  const PaymentStatus(this.value);

  final String value;

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw FormatException('Unknown payment status: $value'),
    );
  }
}

enum AttendanceStatus {
  pending('PENDING'),
  present('PRESENT'),
  absent('ABSENT');

  const AttendanceStatus(this.value);

  final String value;

  static AttendanceStatus fromValue(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () =>
          throw FormatException('Unknown attendance status: $value'),
    );
  }
}

enum ScrutineeringStatus {
  pending('PENDING'),
  passed('PASSED'),
  disqualified('DISQUALIFIED');

  const ScrutineeringStatus(this.value);

  final String value;

  static ScrutineeringStatus fromValue(String value) {
    return ScrutineeringStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () =>
          throw FormatException('Unknown scrutineering status: $value'),
    );
  }
}

class EventRegistrationModel {
  const EventRegistrationModel({
    required this.registrationId,
    required this.eventId,
    required this.userId,
    required this.bikeId,
    required this.riderName,
    required this.bikeName,
    required this.vehicleType,
    required this.pistonDiameterMm,
    required this.paymentProofUrl,
    required this.paymentStatus,
    required this.attendanceStatus,
    required this.scrutineeringStatus,
    required this.registeredAt,
    this.paymentRejectionReason,
    this.verifiedBy,
    this.assignedStartNumber,
    this.attendanceCheckedBy,
    this.attendanceCheckedAt,
    this.measuredPistonMm,
    this.disqualificationReason,
    this.scrutineeredBy,
    this.scrutineeredAt,
    this.scrutineeringHistory = const [],
    this.verifiedAt,
  });

  final String registrationId;
  final String eventId;
  final String userId;
  final String bikeId;
  final String riderName;
  final String bikeName;
  final String vehicleType;
  final double pistonDiameterMm;
  final String paymentProofUrl;
  final PaymentStatus paymentStatus;
  final String? paymentRejectionReason;
  final String? verifiedBy;
  final int? assignedStartNumber;
  final AttendanceStatus attendanceStatus;
  final String? attendanceCheckedBy;
  final DateTime? attendanceCheckedAt;
  final double? measuredPistonMm;
  final ScrutineeringStatus scrutineeringStatus;
  final String? disqualificationReason;
  final String? scrutineeredBy;
  final DateTime? scrutineeredAt;
  final List<Map<String, dynamic>> scrutineeringHistory;
  final DateTime registeredAt;
  final DateTime? verifiedAt;

  factory EventRegistrationModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    if (map['registrationId'] != documentId) {
      throw const FormatException(
        'Registration document ID does not match "registrationId".',
      );
    }

    return EventRegistrationModel(
      registrationId: _requiredString(map, 'registrationId'),
      eventId: _requiredString(map, 'eventId'),
      userId: _requiredString(map, 'userId'),
      bikeId: _requiredString(map, 'bikeId'),
      riderName: _requiredString(map, 'riderName'),
      bikeName: _requiredString(map, 'bikeName'),
      vehicleType: _requiredString(map, 'vehicleType'),
      pistonDiameterMm: _requiredNumber(map, 'pistonDiameterMm').toDouble(),
      paymentProofUrl: _requiredString(map, 'paymentProofUrl'),
      paymentStatus: PaymentStatus.fromValue(
        _requiredString(map, 'paymentStatus'),
      ),
      paymentRejectionReason: _optionalString(
        map,
        'paymentRejectionReason',
      ),
      verifiedBy: _optionalString(map, 'verifiedBy'),
      assignedStartNumber: _optionalInt(map, 'assignedStartNumber'),
      attendanceStatus: AttendanceStatus.fromValue(
        _requiredString(map, 'attendanceStatus'),
      ),
      attendanceCheckedBy: _optionalString(map, 'attendanceCheckedBy'),
      attendanceCheckedAt: _dateTimeOrNull(map['attendanceCheckedAt']),
      measuredPistonMm: _optionalNumber(map, 'measuredPistonMm')?.toDouble(),
      scrutineeringStatus: ScrutineeringStatus.fromValue(
        _requiredString(map, 'scrutineeringStatus'),
      ),
      disqualificationReason: _optionalString(
        map,
        'disqualificationReason',
      ),
      scrutineeredBy: _optionalString(map, 'scrutineeredBy'),
      scrutineeredAt: _dateTimeOrNull(map['scrutineeredAt']),
      scrutineeringHistory: _history(map['scrutineeringHistory']),
      registeredAt: _requiredDateTime(map, 'registeredAt'),
      verifiedAt: _dateTimeOrNull(map['verifiedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'registrationId': registrationId,
        'eventId': eventId,
        'userId': userId,
        'bikeId': bikeId,
        'riderName': riderName,
        'bikeName': bikeName,
        'vehicleType': vehicleType,
        'pistonDiameterMm': pistonDiameterMm,
        'paymentProofUrl': paymentProofUrl,
        'paymentStatus': paymentStatus.value,
        'paymentRejectionReason': paymentRejectionReason,
        'verifiedBy': verifiedBy,
        'assignedStartNumber': assignedStartNumber,
        'attendanceStatus': attendanceStatus.value,
        'attendanceCheckedBy': attendanceCheckedBy,
        'attendanceCheckedAt': attendanceCheckedAt == null
            ? null
            : Timestamp.fromDate(attendanceCheckedAt!),
        'measuredPistonMm': measuredPistonMm,
        'scrutineeringStatus': scrutineeringStatus.value,
        'disqualificationReason': disqualificationReason,
        'scrutineeredBy': scrutineeredBy,
        'scrutineeredAt': scrutineeredAt == null
            ? null
            : Timestamp.fromDate(scrutineeredAt!),
        'scrutineeringHistory': scrutineeringHistory,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'verifiedAt':
            verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
      };

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Missing or invalid "$field" in registration document.',
      );
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Invalid "$field" in registration document.');
    }
    return value;
  }

  static num _requiredNumber(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! num) {
      throw FormatException(
        'Missing or invalid "$field" in registration document.',
      );
    }
    return value;
  }

  static num? _optionalNumber(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is! num) {
      throw FormatException('Invalid "$field" in registration document.');
    }
    return value;
  }

  static int? _optionalInt(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException('Invalid "$field" in registration document.');
    }
    return value;
  }

  static DateTime _requiredDateTime(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = _dateTimeOrNull(map[field]);
    if (value == null) {
      throw FormatException(
        'Missing or invalid "$field" in registration document.',
      );
    }
    return value;
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw const FormatException(
      'Invalid timestamp in registration document.',
    );
  }

  static List<Map<String, dynamic>> _history(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.any((entry) => entry is! Map)) {
      throw const FormatException(
        'Invalid "scrutineeringHistory" in registration document.',
      );
    }
    return value
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }
}
