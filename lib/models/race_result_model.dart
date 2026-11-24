import 'package:cloud_firestore/cloud_firestore.dart';

/// Status hasil balapan sesuai PRD DragHub.
enum RaceResultStatus {
  valid('VALID'),
  breakout('BREAKOUT'),
  jumpStart('JUMP_START'),
  dnf('DNF');

  const RaceResultStatus(this.value);

  final String value;

  static RaceResultStatus fromValue(String value) {
    final normalizedValue = value.trim().toUpperCase();

    return RaceResultStatus.values.firstWhere(
      (status) => status.value == normalizedValue,
      orElse: () => throw FormatException(
        'Unknown race result status: $value',
      ),
    );
  }
}

/// Model hasil satu kali balapan peserta.
///
/// Satu peserta hanya memiliki satu hasil dalam satu event.
/// Dokumen Firestore disarankan menggunakan:
/// race_results/{registrationId}
class RaceResultModel {
  const RaceResultModel({
    required this.resultId,
    required this.eventId,
    required this.registrationId,
    required this.lane,
    required this.reactionTime,
    required this.elapsedTime,
    required this.totalTime,
    required this.status,
    required this.recordedBy,
    required this.recordedAt,
    this.updatedAt,
  });

  /// ID hasil balapan.
  ///
  /// Sesuai aturan proyek, nilainya dapat menggunakan registrationId
  /// agar satu peserta hanya memiliki satu hasil dalam satu event.
  final String resultId;

  /// ID event yang sedang berlangsung.
  final String eventId;

  /// ID pendaftaran peserta.
  final String registrationId;

  /// Jalur balap peserta, hanya 1 atau 2.
  final int lane;

  /// Reaction time dalam satuan detik.
  final double reactionTime;

  /// Elapsed time dalam satuan detik.
  final double elapsedTime;

  /// Total waktu dalam satuan detik.
  ///
  /// Nilainya adalah reactionTime + elapsedTime.
  final double totalTime;

  /// Status akhir hasil balapan.
  final RaceResultStatus status;

  /// UID ofisial yang mencatat hasil balapan.
  final String recordedBy;

  /// Waktu pertama hasil dicatat.
  final DateTime recordedAt;

  /// Waktu terakhir hasil diperbarui.
  final DateTime? updatedAt;

  /// Membuat salinan model dengan nilai tertentu yang diperbarui.
  RaceResultModel copyWith({
    String? resultId,
    String? eventId,
    String? registrationId,
    int? lane,
    double? reactionTime,
    double? elapsedTime,
    double? totalTime,
    RaceResultStatus? status,
    String? recordedBy,
    DateTime? recordedAt,
    DateTime? updatedAt,
  }) {
    return RaceResultModel(
      resultId: resultId ?? this.resultId,
      eventId: eventId ?? this.eventId,
      registrationId: registrationId ?? this.registrationId,
      lane: lane ?? this.lane,
      reactionTime: reactionTime ?? this.reactionTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      totalTime: totalTime ?? this.totalTime,
      status: status ?? this.status,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Membuat model dari dokumen Firestore.
  factory RaceResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid race result document data.',
      );
    }

    return RaceResultModel.fromMap(
      data,
      documentId: doc.id,
    );
  }

  /// Membuat model dari Map.
  factory RaceResultModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final resultId = _requiredString(map, 'resultId');

    if (resultId != documentId) {
      throw const FormatException(
        'Race result document ID does not match "resultId".',
      );
    }

    final lane = _requiredInt(map, 'lane');

    if (lane != 1 && lane != 2) {
      throw const FormatException(
        'Lane must be either 1 or 2.',
      );
    }

    final reactionTime = _requiredNumber(
      map,
      'reactionTime',
    ).toDouble();

    final elapsedTime = _requiredNumber(
      map,
      'elapsedTime',
    ).toDouble();

    final totalTime = _requiredNumber(
      map,
      'totalTime',
    ).toDouble();

    if (reactionTime < 0) {
      throw const FormatException(
        'Reaction time cannot be negative.',
      );
    }

    if (elapsedTime < 0) {
      throw const FormatException(
        'Elapsed time cannot be negative.',
      );
    }

    if (totalTime < 0) {
      throw const FormatException(
        'Total time cannot be negative.',
      );
    }

    return RaceResultModel(
      resultId: resultId,
      eventId: _requiredString(map, 'eventId'),
      registrationId: _requiredString(map, 'registrationId'),
      lane: lane,
      reactionTime: reactionTime,
      elapsedTime: elapsedTime,
      totalTime: totalTime,
      status: RaceResultStatus.fromValue(
        _requiredString(map, 'status'),
      ),
      recordedBy: _requiredString(map, 'recordedBy'),
      recordedAt: _requiredDateTime(map, 'recordedAt'),
      updatedAt: _dateTimeOrNull(map['updatedAt']),
    );
  }

  /// Mengubah model menjadi Map untuk Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'resultId': resultId,
      'eventId': eventId,
      'registrationId': registrationId,
      'lane': lane,
      'reactionTime': reactionTime,
      'elapsedTime': elapsedTime,
      'totalTime': totalTime,
      'status': status.value,
      'recordedBy': recordedBy,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'updatedAt': updatedAt == null
          ? null
          : Timestamp.fromDate(updatedAt!),
    };
  }

  /// Mengecek apakah hasil dapat dihitung sebagai kandidat podium.
  bool get isEligibleForPodium {
    return status == RaceResultStatus.valid;
  }

  /// Mengecek apakah hasil tidak valid untuk peringkat.
  bool get isExcludedFromPodium {
    return status == RaceResultStatus.breakout ||
        status == RaceResultStatus.jumpStart ||
        status == RaceResultStatus.dnf;
  }

  static String _requiredString(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Missing or invalid "$field" in race result document.',
      );
    }

    return value;
  }

  static num _requiredNumber(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];

    if (value is! num) {
      throw FormatException(
        'Missing or invalid "$field" in race result document.',
      );
    }

    return value;
  }

  static int _requiredInt(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];

    if (value is int) {
      return value;
    }

    if (value is num && value == value.toInt()) {
      return value.toInt();
    }

    throw FormatException(
      'Missing or invalid "$field" in race result document.',
    );
  }

  static DateTime _requiredDateTime(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsedDate = DateTime.tryParse(value);

      if (parsedDate != null) {
        return parsedDate;
      }
    }

    throw FormatException(
      'Missing or invalid "$field" in race result document.',
    );
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    throw const FormatException(
      'Invalid date value in race result document.',
    );
  }
}
