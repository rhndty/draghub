import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Buku Kas Komunitas (Koleksi kas_transactions)
/// Sesuai ERD & PRD DragHub v1.4 (Dimiliki oleh Dika / Bendahara)
class KasModel {
  final String transactionId;
  final String title;
  final String category; // 'PENDAFTARAN_EVENT' | 'IURAN_ANGGOTA' | 'SEWA_SIRKUIT' | 'OPERASIONAL'
  final String type; // 'MASUK' | 'KELUAR'
  final int amount; // Nominal Rupiah
  final String recordedBy; // UID Bendahara atau 'MIDTRANS_SANDBOX'
  final String recordedByName; // Nama pencatat, misal 'Dika Bendahara'
  final DateTime transactionDate;
  final String? paymentMethod; // 'MIDTRANS_SANDBOX' | 'MANUAL_TRANSFER' | 'CASH'
  final String? registrationId;
  final String? eventId;
  final String? notes;

  const KasModel({
    required this.transactionId,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.recordedBy,
    this.recordedByName = 'Dika Bendahara',
    required this.transactionDate,
    this.paymentMethod,
    this.registrationId,
    this.eventId,
    this.notes,
  });

  bool get isMasuk => type == 'MASUK';
  bool get isKeluar => type == 'KELUAR';

  String get formattedAmount {
    // Format nominal ke Rupiah sederhana tanpa ketergantungan paket luar
    final digits = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return '${isMasuk ? '+' : '-'} Rp $formatted';
  }

  factory KasModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return KasModel.fromMap(data, doc.id);
  }

  factory KasModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return KasModel(
      transactionId: id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'OPERASIONAL',
      type: (data['type'] ?? 'MASUK').toString().toUpperCase(),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      recordedBy: data['recordedBy'] ?? '',
      recordedByName: data['recordedByName'] ?? 'Dika Bendahara',
      transactionDate: parseDate(data['transactionDate']),
      paymentMethod: data['paymentMethod'],
      registrationId: data['registrationId'],
      eventId: data['eventId'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'title': title,
      'category': category,
      'type': type,
      'amount': amount,
      'recordedBy': recordedBy,
      'recordedByName': recordedByName,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'paymentMethod': paymentMethod,
      'registrationId': registrationId,
      'eventId': eventId,
      'notes': notes,
    };
  }
}
