import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/motorcycle_model.dart';

/// Layanan Pengelolaan Profil Motor Pembalap (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 & ERD v1.4:
/// - Mendata merk (Honda, Yamaha, Suzuki, Kawasaki, Vespa)
/// - Model kendaraan
/// - Tipe transmisi (MATIC / KOPLING)
/// - Diameter piston (mm)
/// - Filter motor yang cocok untuk event tertentu
class MotorcycleService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MotorcycleService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _bikesCollection =>
      _firestore.collection('motorcycles');

  /// Mendengarkan stream motor milik user tertentu (atau yang sedang login)
  Stream<List<MotorcycleModel>> getMyMotorcyclesStream({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _bikesCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final bikes = snapshot.docs.map((doc) {
        return MotorcycleModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();

      // Urutkan berdasarkan waktu pembuatan terbaru jika ada
      bikes.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return bikes;
    });
  }

  /// Menambahkan motor baru ke garasi rider
  Future<String> addMotorcycle({
    required String brand,
    required String modelName,
    required String vehicleType,
    required double pistonDiameterMm,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Rider harus login terlebih dahulu.');
    }

    final normalizedBrand = brand.trim();
    if (!MotorcycleModel.supportedBrands.contains(normalizedBrand)) {
      throw Exception('Merk "$normalizedBrand" tidak didukung.');
    }

    final vType = VehicleType.fromValue(vehicleType.toUpperCase());
    final docRef = _bikesCollection.doc();

    final bike = MotorcycleModel(
      bikeId: docRef.id,
      userId: currentUser.uid,
      brand: normalizedBrand,
      modelName: modelName.trim(),
      vehicleType: vType,
      pistonDiameterMm: pistonDiameterMm,
      createdAt: DateTime.now(),
    );

    await docRef.set(bike.toFirestore());
    return docRef.id;
  }

  /// Menghapus motor dari garasi
  Future<void> deleteMotorcycle(String bikeId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Rider harus login.');
    }

    final doc = await _bikesCollection.doc(bikeId).get();
    if (!doc.exists) {
      throw Exception('Motor tidak ditemukan.');
    }

    if (doc.data()?['userId'] != currentUser.uid) {
      throw Exception('Anda tidak memiliki izin menghapus motor ini.');
    }

    await _bikesCollection.doc(bikeId).delete();
  }

  /// Mengambil daftar motor milik rider yang COCOK dengan event tertentu (PRD 3.1)
  /// Syarat:
  /// 1. Tipe transmisi motor == tipe transmisi event
  /// 2. Diameter piston motor <= batas maksimal piston event
  Future<List<MotorcycleModel>> getEligibleBikesForEvent({
    required String vehicleType,
    required double maxPistonDiameterMm,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    final targetType = VehicleType.fromValue(vehicleType.toUpperCase());

    final snapshot = await _bikesCollection.where('userId', isEqualTo: uid).get();

    final allBikes = snapshot.docs.map((doc) {
      return MotorcycleModel.fromMap(doc.data(), documentId: doc.id);
    }).toList();

    return allBikes.where((bike) {
      return bike.isEligibleFor(
        eventVehicleType: targetType,
        maxPistonDiameterMm: maxPistonDiameterMm,
      );
    }).toList();
  }

  /// Mengambil data satu motor berdasarkan bikeId
  Future<MotorcycleModel?> getMotorcycleById(String bikeId) async {
    final doc = await _bikesCollection.doc(bikeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MotorcycleModel.fromMap(doc.data()!, documentId: doc.id);
  }
}

