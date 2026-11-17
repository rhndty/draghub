import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

/// Layanan Manajemen Event (Milik Alfa / Sekretaris)
/// Mengatur pembuatan draft kejuaraan, validasi kelas motor, dan pemantauan kuota.
class EventService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EventService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Membuat draft event baru oleh Sekretaris
  /// Status awal otomatis 'DRAFT' menunggu approval Ketua/Wakil
  Future<String> createEventDraft({
    required String title,
    required String location,
    required DateTime eventDate,
    required String imageUrl,
    required String vehicleType, // 'MATIC' | 'KOPLING'
    required double maxPistonDiameterMm, // 63.0 / 66.0
    required double bracketSeconds, // 7.0 / 8.0
    required int registrationFee,
    required int quota,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final formattedVehicle = vehicleType.toUpperCase();
    final pistonStr = maxPistonDiameterMm.toStringAsFixed(0);
    final bracketStr = bracketSeconds.toStringAsFixed(0);
    final generatedClassName = '$formattedVehicle s.d ${pistonStr}mm - Braket $bracketStr';

    final docRef = _eventsCollection.doc();
    final eventModel = EventModel(
      eventId: docRef.id,
      title: title.trim(),
      location: location.trim(),
      eventDate: eventDate,
      imageUrl: imageUrl.trim(),
      className: generatedClassName,
      vehicleType: formattedVehicle,
      maxPistonDiameterMm: maxPistonDiameterMm,
      bracketSeconds: bracketSeconds,
      registrationFee: registrationFee,
      quota: quota,
      registeredCount: 0,
      status: 'DRAFT',
      createdBy: currentUser.uid,
      createdAt: DateTime.now(),
    );

    await docRef.set(eventModel.toMap());
    return docRef.id;
  }

  /// Mendengarkan stream semua event atau berdasarkan status tertentu
  Stream<List<EventModel>> getEventsStream({String? status}) {
    Query<Map<String, dynamic>> query =
        _eventsCollection.orderBy('eventDate', descending: false);

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status.toUpperCase());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  /// Mendengarkan stream event yang siap untuk didaftari oleh rider (PUBLISHED)
  Stream<List<EventModel>> getPublishedEventsStream() {
    return _eventsCollection
        .where('status', isEqualTo: 'PUBLISHED')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  /// Mendengarkan stream event yang sedang berlangsung di paddock (ONGOING)
  Stream<List<EventModel>> getOngoingEventsStream() {
    return _eventsCollection
        .where('status', isEqualTo: 'ONGOING')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  /// Mengambil data satu event berdasarkan ID
  Future<EventModel?> getEventById(String eventId) async {
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  /// Validasi kecocokan motor rider dengan kelas event (PRD 3.1):
  /// 1. Tipe transmisi sama (Matic = Matic, Kopling = Kopling)
  /// 2. Piston motor <= batas maksimal piston event
  bool isMotorEligible({
    required String motorVehicleType,
    required double motorPistonMm,
    required EventModel event,
  }) {
    final typeMatches =
        motorVehicleType.toUpperCase() == event.vehicleType.toUpperCase();
    final pistonValid = motorPistonMm <= event.maxPistonDiameterMm;
    return typeMatches && pistonValid;
  }
}

