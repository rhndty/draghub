import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'kas_service.dart';

/// Transaksi Snap yang berhasil dibuat oleh backend.
class MidtransTransaction {
  final String orderId;
  final String token;
  final String redirectUrl;
  final String finishUrl;
  final bool isProduction;

  const MidtransTransaction({
    required this.orderId,
    required this.token,
    required this.redirectUrl,
    required this.finishUrl,
    required this.isProduction,
  });

  factory MidtransTransaction.fromJson(Map<String, dynamic> json) {
    return MidtransTransaction(
      orderId: (json['orderId'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      redirectUrl: (json['redirectUrl'] ?? '').toString(),
      finishUrl: (json['finishUrl'] ?? '').toString(),
      isProduction: json['isProduction'] == true,
    );
  }
}

/// Status transaksi asli dari Midtrans (bukan simulasi).
class MidtransStatus {
  final String orderId;
  final String transactionStatus;
  final String? fraudStatus;
  final String? paymentType;
  final String? statusMessage;
  final String? grossAmount;

  const MidtransStatus({
    required this.orderId,
    required this.transactionStatus,
    this.fraudStatus,
    this.paymentType,
    this.statusMessage,
    this.grossAmount,
  });

  /// Dana sudah benar-benar masuk (settlement) atau kartu berhasil di-capture.
  bool get isPaid =>
      transactionStatus == 'settlement' ||
      (transactionStatus == 'capture' &&
          (fraudStatus == null || fraudStatus == 'accept'));

  bool get isPending => transactionStatus == 'pending';

  bool get isFailed =>
      const ['deny', 'cancel', 'expire', 'failure'].contains(transactionStatus);

  String get label {
    switch (transactionStatus) {
      case 'settlement':
        return 'Pembayaran lunas';
      case 'capture':
        return 'Pembayaran berhasil (kartu)';
      case 'pending':
        return 'Menunggu pembayaran';
      case 'deny':
        return 'Pembayaran ditolak';
      case 'cancel':
        return 'Pembayaran dibatalkan';
      case 'expire':
        return 'Pembayaran kedaluwarsa';
      case 'failure':
        return 'Pembayaran gagal';
      default:
        return transactionStatus;
    }
  }

  factory MidtransStatus.fromJson(Map<String, dynamic> json) {
    return MidtransStatus(
      orderId: (json['orderId'] ?? '').toString(),
      transactionStatus: (json['transactionStatus'] ?? 'unknown').toString(),
      fraudStatus: json['fraudStatus']?.toString(),
      paymentType: json['paymentType']?.toString(),
      statusMessage: json['statusMessage']?.toString(),
      grossAmount: json['grossAmount']?.toString(),
    );
  }
}

/// Service Midtrans DragHub.
///
/// PENTING: Server Key TIDAK disimpan di aplikasi. Aplikasi hanya memanggil
/// backend kecil (folder `midtrans-backend`) yang membuat Snap token dan
/// mengecek status transaksi ke Midtrans.
class MidtransService {
  MidtransService({http.Client? client, KasService? kasService})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _kasService = kasService ?? KasService();

  final http.Client _client;
  final bool _ownsClient;
  final KasService _kasService;

  static const String _configuredBackendUrl = String.fromEnvironment(
    'MIDTRANS_BACKEND_URL',
  );

  /// URL backend. Ubah saat run:
  /// flutter run --dart-define=MIDTRANS_BACKEND_URL=https://xxx.vercel.app
  ///
  /// Default:
  /// - Android emulator: http://10.0.2.2:3000
  /// - Web/desktop/iOS simulator: http://localhost:3000
  static String get backendBaseUrl {
    if (_configuredBackendUrl.isNotEmpty) {
      return _configuredBackendUrl.replaceAll(RegExp(r'/+$'), '');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static bool get isUsingLocalBackend {
    final uri = Uri.tryParse(backendBaseUrl);
    if (uri == null) return false;
    return uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2';
  }

  /// Nomor order unik. Midtrans menolak order_id yang sudah dipakai.
  static String generateOrderId(String registrationId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final cleanReg = registrationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleanReg.length > 12
        ? cleanReg.substring(cleanReg.length - 12)
        : cleanReg;
    return 'DRAGHUB-${timestamp.substring(timestamp.length - 9)}-$suffix';
  }

  /// Meminta backend membuat transaksi Snap.
  Future<MidtransTransaction> createTransaction({
    required String registrationId,
    required String eventId,
    required String eventTitle,
    required String riderName,
    required int amount,
    String? orderId,
  }) async {
    final effectiveOrderId = orderId ?? generateOrderId(registrationId);

    final uri = Uri.parse('$backendBaseUrl/api/create-transaction');
    final response = await _client
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // Lewati halaman peringatan ngrok versi gratis.
            'ngrok-skip-browser-warning': 'true',
          },
          body: jsonEncode({
            'orderId': effectiveOrderId,
            'grossAmount': amount,
            'customerName': riderName,
            'customerEmail': 'rider@draghub.local',
            'itemName': 'Pendaftaran $eventTitle',
          }),
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(data, response.statusCode));
    }

    final transaction = MidtransTransaction.fromJson(data);
    if (transaction.token.isEmpty || transaction.redirectUrl.isEmpty) {
      throw Exception(
        'Backend tidak mengembalikan token/redirect_url Midtrans.',
      );
    }
    return transaction;
  }

  /// Mengecek status transaksi langsung dari Midtrans via backend.
  Future<MidtransStatus> getStatus(String orderId) async {
    final uri = Uri.parse(
      '$backendBaseUrl/api/status/${Uri.encodeComponent(orderId)}',
    );
    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            // Lewati halaman peringatan ngrok versi gratis.
            'ngrok-skip-browser-warning': 'true',
          },
        )
        .timeout(const Duration(seconds: 20));

    // Transaksi yang baru dibuat kadang belum terbaca sesaat.
    if (response.statusCode == 404) {
      return MidtransStatus(orderId: orderId, transactionStatus: 'pending');
    }

    final data = _decodeBody(response);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(data, response.statusCode));
    }
    return MidtransStatus.fromJson(data);
  }

  /// Menunggu status berubah dari pending menjadi settlement.
  /// Midtrans kadang butuh beberapa detik untuk mengubah status.
  Future<MidtransStatus> waitForFinalStatus(
    String orderId, {
    int attempts = 6,
    Duration interval = const Duration(seconds: 2),
  }) async {
    MidtransStatus status = MidtransStatus(
      orderId: orderId,
      transactionStatus: 'pending',
    );

    for (var i = 0; i < attempts; i++) {
      status = await getStatus(orderId);
      if (status.isPaid || status.isFailed) return status;
      if (i < attempts - 1) await Future.delayed(interval);
    }
    return status;
  }

  /// Menulis hasil pembayaran ke Firestore (status PAID, nomor balap, buku kas).
  Future<int> finalizeSuccessfulPayment({
    required String registrationId,
    required String eventId,
    required String orderId,
    required String paymentChannel,
    required int amount,
  }) {
    return _kasService.processMidtransPaymentSuccess(
      registrationId: registrationId,
      eventId: eventId,
      orderId: orderId,
      paymentChannel: paymentChannel,
      amount: amount,
    );
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': response.body};
    }
  }

  String _errorMessage(Map<String, dynamic> data, int statusCode) {
    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) return error;

    final details = data['details'];
    if (details is Map && details['status_message'] != null) {
      return details['status_message'].toString();
    }
    return 'Request ke backend Midtrans gagal (HTTP $statusCode).';
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
