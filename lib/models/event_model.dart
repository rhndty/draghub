import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Entitas Event (Satu Event = Satu Kelas)
/// Sesuai ERD & PRD DragHub v1.4
class EventModel {
  final String eventId;
  final String title;
  final String location;
  final DateTime eventDate;
  final String imageUrl;
  final String className;
  final String vehicleType; // 'MATIC' | 'KOPLING'
  final double maxPistonDiameterMm; // contoh: 63.0, 66.0
  final double bracketSeconds; // contoh: 7.0, 8.0
  final int registrationFee; // Biaya pendaftaran (Rp)
  final int quota; // Kuota total peserta
  final int registeredCount; // Jumlah peserta lunas (counter nomor balap)
  final String
  status; // 'DRAFT' | 'PUBLISHED' | 'ONGOING' | 'COMPLETED' | 'REJECTED'
  final String createdBy; // UID Sekretaris pembuat draft
  final String? approvedBy; // UID Ketua/Wakil yang approve
  final List<Map<String, dynamic>>? podium; // Snapshot juara 1-3 saat COMPLETED
  final DateTime? completedAt;
  final DateTime? attendanceClosedAt; // Waktu verifikasi kehadiran ditutup
  final DateTime createdAt;

  const EventModel({
    required this.eventId,
    required this.title,
    required this.location,
    required this.eventDate,
    required this.imageUrl,
    required this.className,
    required this.vehicleType,
    required this.maxPistonDiameterMm,
    required this.bracketSeconds,
    required this.registrationFee,
    required this.quota,
    this.registeredCount = 0,
    this.status = 'DRAFT',
    required this.createdBy,
    this.approvedBy,
    this.podium,
    this.completedAt,
    this.attendanceClosedAt,
    required this.createdAt,
  });

  /// Sisa kuota peserta yang masih tersedia (PRD v1.4)
  int get remainingQuota {
    final remaining = quota - registeredCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Mengecek apakah pendaftaran saat ini sedang dibuka
  bool get isRegistrationOpen => status == 'PUBLISHED' && remainingQuota > 0;

  bool get isDraft => status == 'DRAFT';
  bool get isPublished => status == 'PUBLISHED';
  bool get isOngoing => status == 'ONGOING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isRejected => status == 'REJECTED';
  bool get isAttendanceClosed => attendanceClosedAt != null;

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return EventModel.fromMap(data, doc.id);
  }

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    List<Map<String, dynamic>>? parsePodium(dynamic list) {
      if (list is List) {
        return list
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return null;
    }

    return EventModel(
      eventId: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      eventDate: parseDate(data['eventDate']),
      imageUrl: data['imageUrl'] ?? '',
      className: data['className'] ?? '',
      vehicleType: (data['vehicleType'] ?? 'MATIC').toString().toUpperCase(),
      maxPistonDiameterMm:
          (data['maxPistonDiameterMm'] as num?)?.toDouble() ?? 63.0,
      bracketSeconds: (data['bracketSeconds'] as num?)?.toDouble() ?? 7.0,
      registrationFee: (data['registrationFee'] as num?)?.toInt() ?? 0,
      quota: (data['quota'] as num?)?.toInt() ?? 0,
      registeredCount: (data['registeredCount'] as num?)?.toInt() ?? 0,
      status: (data['status'] ?? 'DRAFT').toString().toUpperCase(),
      createdBy: data['createdBy'] ?? '',
      approvedBy: data['approvedBy'],
      podium: parsePodium(data['podium']),
      completedAt: parseNullableDate(data['completedAt']),
      attendanceClosedAt: parseNullableDate(data['attendanceClosedAt']),
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'location': location,
      'eventDate': Timestamp.fromDate(eventDate),
      'imageUrl': imageUrl,
      'className': className,
      'vehicleType': vehicleType,
      'maxPistonDiameterMm': maxPistonDiameterMm,
      'bracketSeconds': bracketSeconds,
      'registrationFee': registrationFee,
      'quota': quota,
      'registeredCount': registeredCount,
      'status': status,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'podium': podium,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'attendanceClosedAt': attendanceClosedAt != null
          ? Timestamp.fromDate(attendanceClosedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
