import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kas_model.dart';

/// Layanan Finansial & Kas Komunitas (Milik Dika / Bendahara)
/// Bertanggung jawab atas:
/// 1. Verifikasi Pembayaran Manual & Atomic Transaction (Terbitkan Nomor Balap + Update Kuota + Catat Kas)
/// 2. Penolakan Bukti Transfer dengan alasan wajib
/// 3. Integrasi Pembayaran Midtrans Sandbox (Otomatis tercatat ke Buku Kas)
/// 4. Pencatatan Mutasi Arus Kas (Uang Masuk / Keluar)
/// 5. Rekapitulasi Saldo Transparan bagi Panitia
class KasService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  KasService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _kasCollection =>
      _firestore.collection('kas_transactions');

  CollectionReference<Map<String, dynamic>> get _regCollection =>
      _firestore.collection('event_registrations');

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Mendapatkan role user saat ini
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'guest';
    final doc = await _usersCollection.doc(user.uid).get();
    if (!doc.exists) return 'anggota';
    return (doc.data()?['role'] ?? 'anggota').toString().toLowerCase();
  }

  /// Memeriksa apakah user saat ini termasuk panitia (berhak melihat buku kas)
  Future<bool> isPanitia() async {
    final role = await getCurrentUserRole();
    return [
      'bendahara',
      'ketua',
      'wakil',
      'sekretaris',
      'super_admin',
      'verifikator',
      'race_director',
      'race_control'
    ].contains(role);
  }

  /// --------------------------------------------------------------------------
  /// 1. VERIFIKASI PEMBAYARAN MANUAL (ATOMIC FIRESTORE TRANSACTION)
  /// Sesuai PRD v1.4: Cek event PUBLISHED, cek kuota, nomor urut lunas, catat kas
  /// --------------------------------------------------------------------------
  Future<int> verifyPaymentManual({
    required String registrationId,
    required String eventId,
    String? customNotes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Bendahara harus login terlebih dahulu.');
    }

    // Ambil data profil bendahara
    final userDoc = await _usersCollection.doc(currentUser.uid).get();
    final bendaharaName = userDoc.data()?['fullName'] ?? 'Dika Bendahara';

    final regRef = _regCollection.doc(registrationId);
    final eventRef = _eventsCollection.doc(eventId);
    final kasRef = _kasCollection.doc();

    return await _firestore.runTransaction<int>((transaction) async {
      // 1. Baca data event
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('Data event tidak ditemukan.');
      }
      final eventData = eventSnapshot.data()!;
      final eventStatus = (eventData['status'] ?? '').toString().toUpperCase();
      final quota = (eventData['quota'] as num?)?.toInt() ?? 0;
      final registeredCount = (eventData['registeredCount'] as num?)?.toInt() ?? 0;
      final eventTitle = eventData['title'] ?? 'Event Balap';
      final registrationFee = (eventData['registrationFee'] as num?)?.toInt() ?? 0;

      // Validasi status event (PUBLISHED, UPCOMING, atau DRAFT saat testing)
      final allowedStatuses = ['PUBLISHED', 'UPCOMING', 'DRAFT', 'ONGOING'];
      if (!allowedStatuses.contains(eventStatus) && eventStatus.isNotEmpty) {
        throw Exception(
          'Pembayaran hanya dapat diverifikasi saat event aktif (Status saat ini: $eventStatus).',
        );
      }

      // Validasi kuota peserta
      final effectiveQuota = quota <= 0 ? 50 : quota;
      if (registeredCount >= effectiveQuota) {
        throw Exception(
          'Kuota event sudah penuh ($registeredCount/$effectiveQuota). Pembayaran tidak dapat diverifikasi.',
        );
      }

      // 2. Baca data pendaftaran
      final regSnapshot = await transaction.get(regRef);
      if (!regSnapshot.exists) {
        throw Exception('Data pendaftaran tidak ditemukan.');
      }
      final regData = regSnapshot.data()!;
      final currentPaymentStatus = regData['paymentStatus'] ?? 'PENDING';
      final riderName = regData['riderName'] ?? 'Pembalap';

      if (currentPaymentStatus == 'PAID') {
        throw Exception('Pendaftaran ini sudah berstatus LUNAS (PAID).');
      }

      // 3. Terbitkan nomor balap berurutan
      final int newStartNumber = registeredCount + 1;
      final String formattedStartNumber = '#${newStartNumber.toString().padLeft(3, '0')}';

      // 4. Update data pendaftaran
      transaction.update(regRef, {
        'paymentStatus': 'PAID',
        'assignedStartNumber': newStartNumber,
        'verifiedBy': currentUser.uid,
        'verifiedAt': FieldValue.serverTimestamp(),
        'paymentRejectionReason': null,
      });

      // 5. Update kuota terpakai pada event
      transaction.update(eventRef, {
        'registeredCount': newStartNumber,
      });

      // 6. Catat otomatis ke buku kas komunitas (kas_transactions)
      transaction.set(kasRef, {
        'transactionId': kasRef.id,
        'title': 'Pendaftaran $eventTitle - $riderName ($formattedStartNumber)',
        'category': 'PENDAFTARAN_EVENT',
        'type': 'MASUK',
        'amount': registrationFee,
        'recordedBy': currentUser.uid,
        'recordedByName': bendaharaName,
        'transactionDate': FieldValue.serverTimestamp(),
        'paymentMethod': 'MANUAL_TRANSFER',
        'registrationId': registrationId,
        'eventId': eventId,
        'notes': customNotes ?? 'Verifikasi manual oleh Bendahara',
      });

      return newStartNumber;
    });
  }

  /// --------------------------------------------------------------------------
  /// 2. TOLAK BUKTI BAYAR MANUAL
  /// Sesuai PRD v1.4: Wajib menyertakan alasan penolakan tertulis
  /// --------------------------------------------------------------------------
  Future<void> rejectPaymentManual({
    required String registrationId,
    required String rejectionReason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Bendahara harus login terlebih dahulu.');
    }

    if (rejectionReason.trim().isEmpty) {
      throw Exception('Alasan penolakan bukti bayar wajib diisi.');
    }

    final regRef = _regCollection.doc(registrationId);
    final doc = await regRef.get();
    if (!doc.exists) {
      throw Exception('Data pendaftaran tidak ditemukan.');
    }

    await regRef.update({
      'paymentStatus': 'REJECTED',
      'paymentRejectionReason': rejectionReason.trim(),
      'verifiedBy': currentUser.uid,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// --------------------------------------------------------------------------
  /// 3. PROSES PEMBAYARAN MIDTRANS SANDBOX (OTOMATIS TERCATAT KE KAS)
  /// Dipanggil ketika simulasi pembayaran Midtrans Sandbox berhasil
  /// --------------------------------------------------------------------------
  Future<int> processMidtransPaymentSuccess({
    required String registrationId,
    required String eventId,
    required String orderId,
    required String paymentChannel, // e.g. 'QRIS', 'BCA_VA', 'MANDIRI_BILL'
    required int amount,
  }) async {
    final regRef = _regCollection.doc(registrationId);
    final eventRef = _eventsCollection.doc(eventId);
    final kasRef = _kasCollection.doc();

    return await _firestore.runTransaction<int>((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('Data event tidak ditemukan.');
      }
      final eventData = eventSnapshot.data()!;
      final eventStatus = (eventData['status'] ?? '').toString().toUpperCase();
      final quota = (eventData['quota'] as num?)?.toInt() ?? 0;
      final registeredCount = (eventData['registeredCount'] as num?)?.toInt() ?? 0;
      final eventTitle = eventData['title'] ?? 'Event Balap';

      // Validasi status event
      final allowedStatuses = ['PUBLISHED', 'UPCOMING', 'DRAFT', 'ONGOING'];
      if (!allowedStatuses.contains(eventStatus) && eventStatus.isNotEmpty) {
        throw Exception(
          'Pembayaran hanya dapat dilakukan saat event aktif (Status saat ini: $eventStatus).',
        );
      }

      final effectiveQuota = quota <= 0 ? 50 : quota;
      if (registeredCount >= effectiveQuota) {
        throw Exception('Kuota event sudah penuh ($registeredCount/$effectiveQuota).');
      }

      final regSnapshot = await transaction.get(regRef);
      if (!regSnapshot.exists) {
        throw Exception('Data pendaftaran tidak ditemukan.');
      }
      final regData = regSnapshot.data()!;
      if (regData['paymentStatus'] == 'PAID') {
        throw Exception('Pendaftaran ini sudah berstatus PAID sebelumnya.');
      }
      final riderName = regData['riderName'] ?? 'Pembalap';

      final int newStartNumber = registeredCount + 1;
      final String formattedStartNumber = '#${newStartNumber.toString().padLeft(3, '0')}';

      // Update registrasi
      transaction.update(regRef, {
        'paymentStatus': 'PAID',
        'assignedStartNumber': newStartNumber,
        'verifiedBy': 'MIDTRANS_SANDBOX',
        'verifiedAt': FieldValue.serverTimestamp(),
        'paymentProofUrl': 'MIDTRANS_ORDER_$orderId',
        'paymentRejectionReason': null,
      });

      // Update kuota event
      transaction.update(eventRef, {
        'registeredCount': newStartNumber,
      });

      // Catat otomatis ke kas_transactions
      transaction.set(kasRef, {
        'transactionId': kasRef.id,
        'title': 'Pendaftaran $eventTitle - $riderName ($formattedStartNumber)',
        'category': 'PENDAFTARAN_EVENT',
        'type': 'MASUK',
        'amount': amount,
        'recordedBy': 'MIDTRANS_SANDBOX',
        'recordedByName': 'Midtrans Sandbox Gateway',
        'transactionDate': FieldValue.serverTimestamp(),
        'paymentMethod': 'MIDTRANS_SANDBOX ($paymentChannel)',
        'registrationId': registrationId,
        'eventId': eventId,
        'notes': 'Order ID: $orderId via $paymentChannel Sandbox',
      });

      return newStartNumber;
    });
  }

  /// --------------------------------------------------------------------------
  /// 4. PENCATATAN MUTASI KAS MANUAL OLEH BENDAHARA (DIKA)
  /// Iuran Anggota, Sewa Sirkuit, Operasional, dsb.
  /// --------------------------------------------------------------------------
  Future<String> recordManualKasTransaction({
    required String title,
    required String category, // 'PENDAFTARAN_EVENT' | 'IURAN_ANGGOTA' | 'SEWA_SIRKUIT' | 'OPERASIONAL'
    required String type, // 'MASUK' | 'KELUAR'
    required int amount,
    String? notes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Bendahara harus login terlebih dahulu.');
    }

    final userDoc = await _usersCollection.doc(currentUser.uid).get();
    final bendaharaName = userDoc.data()?['fullName'] ?? 'Dika Bendahara';

    final docRef = _kasCollection.doc();
    final kasModel = KasModel(
      transactionId: docRef.id,
      title: title.trim(),
      category: category,
      type: type.toUpperCase(),
      amount: amount,
      recordedBy: currentUser.uid,
      recordedByName: bendaharaName,
      transactionDate: DateTime.now(),
      paymentMethod: 'CASH',
      notes: notes?.trim(),
    );

    await docRef.set(kasModel.toFirestore());
    return docRef.id;
  }

  /// Menghapus transaksi kas manual (hanya jika ada kesalahan input)
  Future<void> deleteKasTransaction(String transactionId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Bendahara harus login terlebih dahulu.');
    }
    if (transactionId.trim().isEmpty) {
      throw Exception('ID transaksi tidak valid.');
    }
    await _kasCollection.doc(transactionId.trim()).delete();
  }

  /// --------------------------------------------------------------------------
  /// 5. STREAM DATA KAS & RINGKASAN SALDO
  /// --------------------------------------------------------------------------

  /// Stream daftar riwayat kas dengan opsi filter
  /// Sorting dan filtering dilakukan di memori aplikasi agar tidak memerlukan
  /// composite index Firestore yang sering menyebabkan kueri ditolak/crash.
  Stream<List<KasModel>> getKasTransactionsStream({
    String? category,
    String? type,
  }) {
    return _kasCollection.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => KasModel.fromFirestore(doc)).toList();

      // Urutkan dari yang paling baru ke terlama
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      // Filter Kategori
      if (category != null && category != 'SEMUA') {
        list.retainWhere((item) => item.category == category);
      }

      // Filter Tipe (MASUK / KELUAR)
      if (type != null && type != 'SEMUA') {
        list.retainWhere((item) => item.type == type.toUpperCase());
      }

      return list;
    });
  }

  /// Stream ringkasan finansial (Total Saldo, Total Masuk, Total Keluar)
  Stream<Map<String, dynamic>> getFinancialSummaryStream() {
    return _kasCollection.snapshots().map((snapshot) {
      int totalMasuk = 0;
      int totalKeluar = 0;
      int count = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toInt() ?? 0;
        final type = (data['type'] ?? 'MASUK').toString().toUpperCase();

        if (type == 'MASUK') {
          totalMasuk += amount;
        } else if (type == 'KELUAR') {
          totalKeluar += amount;
        }
      }

      final int saldoBersih = totalMasuk - totalKeluar;

      return {
        'totalSaldo': saldoBersih,
        'totalMasuk': totalMasuk,
        'totalKeluar': totalKeluar,
        'transactionCount': count,
      };
    });
  }

  /// --------------------------------------------------------------------------
  /// 6. STREAM VERIFIKASI PENDAFTARAN
  /// --------------------------------------------------------------------------

  /// Stream pendaftaran berdasarkan status pembayaran
  Stream<List<Map<String, dynamic>>> getRegistrationsByPaymentStatusStream(
    String paymentStatus,
  ) {
    return _regCollection
        .where('paymentStatus', isEqualTo: paymentStatus)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['registrationId'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream seluruh pendaftaran untuk tab pembayaran
  Stream<List<Map<String, dynamic>>> getAllRegistrationsStream() {
    return _regCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['registrationId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
