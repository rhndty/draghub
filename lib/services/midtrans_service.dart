import 'dart:math';
import 'package:flutter/foundation.dart';
import 'kas_service.dart';

/// Service Integrasi Midtrans Payment Gateway (Mode Sandbox)
/// Sesuai permintaan khusus: Pembayaran via Midtrans Sandbox langsung otomatis tercatat ke buku kas.
class MidtransService {
  final KasService _kasService = KasService();

  // Konfigurasi Kunci Midtrans Sandbox (Testing Environment)
  static const String merchantId = 'G123456789';
  static const String clientKey = 'SB-Mid-client-W_xSampleSandboxKey123';
  static const String serverKey = 'SB-Mid-server-SampleServerKey123';
  static const String sandboxBaseUrl = 'https://app.sandbox.midtrans.com/snap/v1';

  /// Menghasilkan nomor Order ID unik untuk transaksi Midtrans Sandbox
  static String generateOrderId(String registrationId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final cleanReg = registrationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleanReg.length > 4 ? cleanReg.substring(cleanReg.length - 4) : cleanReg;
    return 'MIDTRANS-SBX-${timestamp.substring(timestamp.length - 6)}-$suffix';
  }

  /// Menghasilkan nomor Virtual Account simulasi untuk bank pilihan
  static String generateVirtualAccount(String bank) {
    final randomDigits = (10000000 + Random().nextInt(90000000)).toString();
    switch (bank.toUpperCase()) {
      case 'BCA':
        return '70012$randomDigits';
      case 'BNI':
        return '8808$randomDigits';
      case 'BRI':
        return '10777$randomDigits';
      case 'MANDIRI':
        return '70012$randomDigits';
      default:
        return '89100$randomDigits';
    }
  }

  /// Memproses pembayaran sukses dari Midtrans Sandbox
  /// Langsung memicu transaksi atomic di Firestore:
  /// 1. Status pendaftaran jadi PAID
  /// 2. Nomor balap resmi diterbitkan (#001 dst)
  /// 3. Kuota terpakai event bertambah
  /// 4. Otomatis tercatat di riwayat buku kas (kas_transactions)
  Future<int> payWithMidtransSandbox({
    required String registrationId,
    required String eventId,
    required int amount,
    required String paymentChannel,
    String? orderId,
  }) async {
    final effectiveOrderId = orderId ?? generateOrderId(registrationId);

    debugPrint('Memulai proses simulasi Midtrans Sandbox:');
    debugPrint('Order ID: $effectiveOrderId');
    debugPrint('Channel: $paymentChannel');
    debugPrint('Amount: Rp $amount');

    // Simulasi delay jaringan payment gateway 1.2 detik
    await Future.delayed(const Duration(milliseconds: 1200));

    // Eksekusi transaksi Firestore atomik via KasService
    final newStartNumber = await _kasService.processMidtransPaymentSuccess(
      registrationId: registrationId,
      eventId: eventId,
      orderId: effectiveOrderId,
      paymentChannel: paymentChannel,
      amount: amount,
    );

    debugPrint('Midtrans Sandbox Berhasil! Nomor balap: #$newStartNumber tercatat ke Buku Kas.');
    return newStartNumber;
  }
}
