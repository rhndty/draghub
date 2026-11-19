import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/motorcycle_model.dart';

/// Layanan Pengelolaan Profil Motor Pembalap (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4 (Bab 4.1) & ERD v1.4 (Bab 2.2):
/// - Koleksi root Firestore: 'motorcycles'
/// - Atribut: bikeId, userId, brand (Honda/Yamaha/Suzuki/Kawasaki/Vespa), modelName, vehicleType (MATIC/KOPLING), pistonDiameterMm, createdAt
/// - Filter kecocokan motor dengan event balap (PRD 3.1)
class MotorcycleService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MotorcycleService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _bikesCollection =>
      _firestore.collection('motorcycles');

  /// Mendengarkan stream daftar motor balap milik pengguna yang sedang login
  Stream<List<MotorcycleModel>> getMyMotorcyclesStream({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _bikesCollection.where('userId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      final bikes = <MotorcycleModel>[];
      for (final doc in snapshot.docs) {
        try {
          bikes.add(MotorcycleModel.fromMap(doc.data(), documentId: doc.id));
        } catch (_) {
          // Abaikan dokumen yang tidak sesuai skema
        }
      }

      // Urutkan motor berdasarkan waktu penambahan terbaru
      bikes.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return bikes;
    });
  }

  /// Menambahkan motor baru ke garasi rider (PRD 4.1)
  /// Merk didukung: Honda, Yamaha, Suzuki, Kawasaki, Vespa
  /// Tipe kendaraan: MATIC atau KOPLING
  /// Diameter piston: mm (contoh: 59, 60, 62, 63, 66)
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
      throw Exception(
        'Merk "$normalizedBrand" tidak didukung. Pilihan: ${MotorcycleModel.supportedBrands.join(', ')}',
      );
    }

    if (modelName.trim().isEmpty) {
      throw Exception('Nama/model kendaraan tidak boleh kosong.');
    }

    if (pistonDiameterMm <= 0) {
      throw Exception('Ukuran diameter piston harus berupa angka positif.');
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

  /// Menghapus motor dari garasi rider
  Future<void> deleteMotorcycle(String bikeId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Rider harus login.');
    }

    final doc = await _bikesCollection.doc(bikeId).get();
    if (!doc.exists) {
      throw Exception('Data motor tidak ditemukan.');
    }

    if (doc.data()?['userId'] != currentUser.uid) {
      throw Exception(
        'Anda tidak memiliki wewenang untuk menghapus motor ini.',
      );
    }

    await _bikesCollection.doc(bikeId).delete();
  }

  /// Mengambil daftar motor milik rider yang memenuhi syarat kelas event (PRD 3.1)
  /// Syarat Lolos Seleksi Pendaftaran:
  /// 1. Tipe transmisi motor == tipe transmisi event (MATIC / KOPLING)
  /// 2. Diameter piston motor <= batas maksimal piston event
  Future<List<MotorcycleModel>> getEligibleBikesForEvent({
    required String vehicleType,
    required double maxPistonDiameterMm,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return [];

    final targetType = VehicleType.fromValue(vehicleType.toUpperCase());
    final snapshot = await _bikesCollection
        .where('userId', isEqualTo: uid)
        .get();

    final eligibleBikes = <MotorcycleModel>[];
    for (final doc in snapshot.docs) {
      try {
        final bike = MotorcycleModel.fromMap(doc.data(), documentId: doc.id);
        if (bike.isEligibleFor(
          eventVehicleType: targetType,
          maxPistonDiameterMm: maxPistonDiameterMm,
        )) {
          eligibleBikes.add(bike);
        }
      } catch (_) {}
    }

    return eligibleBikes;
  }
}
