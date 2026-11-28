import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/midtrans_service.dart';
import '../theme/app_colors.dart';
import 'midtrans_snap_page.dart';

/// Bottom Sheet Pembayaran Midtrans Snap (SUNGGUHAN, bukan simulasi).
///
/// Alur:
/// 1. Flutter minta backend membuat Snap token.
/// 2. Pengguna membayar di halaman Snap (WebView / browser).
/// 3. Setelah kembali, status transaksi dicek ke Midtrans lewat backend.
/// 4. Kalau settlement/capture, pendaftaran jadi PAID, nomor balap terbit,
///    dan transaksi masuk buku kas.
class MidtransPaymentSheet extends StatefulWidget {
  final String registrationId;
  final String eventId;
  final String eventTitle;
  final String riderName;
  final int amount;
  final Function(int assignedStartNumber)? onPaymentSuccess;

  const MidtransPaymentSheet({
    super.key,
    required this.registrationId,
    required this.eventId,
    required this.eventTitle,
    required this.riderName,
    required this.amount,
    this.onPaymentSuccess,
  });

  @override
  State<MidtransPaymentSheet> createState() => _MidtransPaymentSheetState();
}

class _MidtransPaymentSheetState extends State<MidtransPaymentSheet> {
  final MidtransService _midtransService = MidtransService();

  late String _orderId;
  bool _isProcessing = false;
  bool _isCreatingTransaction = false;

  MidtransTransaction? _lastTransaction;
  MidtransStatus? _lastStatus;
  int? _successStartNumber;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _orderId = MidtransService.generateOrderId(widget.registrationId);
  }

  @override
  void dispose() {
    _midtransService.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  Future<void> _startPayment() async {
    // Kalau transaksi sebelumnya masih pending, buka halaman yang sama.
    // Jangan buat order baru supaya tidak terjadi pembayaran ganda.
    final existing = _lastTransaction;
    if (existing != null && (_lastStatus == null || _lastStatus!.isPending)) {
      if (kIsWeb) {
        await _openPaymentInBrowser(existing);
      } else {
        await _openPaymentInWebView(existing);
      }
      return;
    }

    setState(() {
      _isCreatingTransaction = true;
      _lastError = null;
    });

    try {
      final transaction = await _midtransService.createTransaction(
        registrationId: widget.registrationId,
        eventId: widget.eventId,
        eventTitle: widget.eventTitle,
        riderName: widget.riderName,
        amount: widget.amount,
      );

      if (!mounted) return;
      setState(() {
        _lastTransaction = transaction;
        _orderId = transaction.orderId;
        _isCreatingTransaction = false;
      });

      if (kIsWeb) {
        await _openPaymentInBrowser(transaction);
      } else {
        await _openPaymentInWebView(transaction);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingTransaction = false;
        _lastError = e.toString().replaceFirst('Exception: ', '');
      });
      _showError('Gagal membuat transaksi Midtrans: $_lastError');
    }
  }

  Future<void> _openPaymentInWebView(MidtransTransaction transaction) async {
    final finished = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MidtransSnapPage(
          redirectUrl: transaction.redirectUrl,
          finishUrl: transaction.finishUrl,
          title: transaction.isProduction
              ? 'Pembayaran Midtrans'
              : 'Pembayaran Midtrans (Sandbox)',
        ),
      ),
    );

    if (!mounted) return;
    if (finished == true) {
      await _checkStatus(transaction);
    } else {
      setState(() {
        _lastStatus = MidtransStatus(
          orderId: transaction.orderId,
          transactionStatus: 'pending',
        );
      });
    }
  }

  Future<void> _openPaymentInBrowser(MidtransTransaction transaction) async {
    final shouldCheck = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lanjutkan Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Halaman pembayaran Midtrans akan dibuka di tab baru. '
          'Setelah selesai, kembali ke tab ini lalu tekan "Saya Sudah Bayar".\n\n'
          'Order ID: ${transaction.orderId}',
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('TUTUP'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
            ),
            onPressed: () async {
              final opened = await launchUrl(
                Uri.parse(transaction.redirectUrl),
                mode: LaunchMode.externalApplication,
              );
              if (!opened && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Browser tidak bisa dibuka. Salin URL manual.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('BUKA PEMBAYARAN'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SAYA SUDAH BAYAR'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (shouldCheck == true) {
      await _checkStatus(transaction);
    }
  }

  Future<void> _checkStatus(MidtransTransaction transaction) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final status = await _midtransService.waitForFinalStatus(
        transaction.orderId,
      );

      if (!mounted) return;

      if (status.isPaid) {
        await _finalizePayment(transaction, status);
        return;
      }

      setState(() {
        _lastStatus = status;
        _isProcessing = false;
      });

      if (status.isFailed) {
        _showError(
          'Pembayaran ${status.label.toLowerCase()}. Silakan coba lagi.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lastError = e.toString().replaceFirst('Exception: ', '');
      });
      _showError('Gagal mengecek status pembayaran: $_lastError');
    }
  }

  Future<void> _finalizePayment(
    MidtransTransaction transaction,
    MidtransStatus status,
  ) async {
    try {
      final startNumber = await _midtransService.finalizeSuccessfulPayment(
        registrationId: widget.registrationId,
        eventId: widget.eventId,
        orderId: transaction.orderId,
        paymentChannel: status.paymentType ?? 'MIDTRANS',
        amount: widget.amount,
      );

      if (!mounted) return;
      setState(() {
        _successStartNumber = startNumber;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lastStatus = status;
        _lastError = e.toString().replaceFirst('Exception: ', '');
      });
      _showError(
        'Pembayaran terdeteksi lunas, tetapi gagal menyimpan ke Firestore: '
        '$_lastError\nOrder ID: ${transaction.orderId}',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _closeWithSuccess() {
    final startNumber = _successStartNumber;
    Navigator.pop(context);
    if (startNumber != null) {
      widget.onPaymentSuccess?.call(startNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: _successStartNumber != null
            ? _buildSuccessView()
            : _buildPaymentView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 16),
        const Text(
          'PEMBAYARAN MIDTRANS BERHASIL!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nomor Balap Resmi Diterbitkan:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryMaroon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryMaroon),
          ),
          child: Text(
            '#${_successStartNumber!.toString().padLeft(3, '0')}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryMaroon,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Transaksi telah otomatis dicatat ke dalam Buku Kas Komunitas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _closeWithSuccess,
            child: const Text(
              'OK, MANTAP!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentView() {
    final transaction = _lastTransaction;
    final status = _lastStatus;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Midtrans Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (transaction?.isProduction ?? false)
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (transaction?.isProduction ?? false)
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Text(
                (transaction?.isProduction ?? false) ? 'PRODUCTION' : 'SANDBOX',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (transaction?.isProduction ?? false)
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rincian Tagihan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildDetailRow('Event', widget.eventTitle),
              const SizedBox(height: 6),
              _buildDetailRow('Pembalap', widget.riderName),
              const SizedBox(height: 6),
              _buildDetailRow('Order ID', _orderId, monospace: true),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(widget.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status pembayaran terakhir
        if (status != null) _buildStatusBanner(status),

        // Info metode pembayaran
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.blue.shade800,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pembayaran aman via Midtrans',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Mendukung QRIS, GoPay, ShopeePay, Virtual Account BCA/BNI/BRI/'
                'Mandiri/Permata, dan kartu kredit/debit. Status pembayaran '
                'diverifikasi langsung ke Midtrans, bukan simulasi.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade900,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tombol aksi
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: (_isProcessing || _isCreatingTransaction)
                ? null
                : _startPayment,
            icon: (_isProcessing || _isCreatingTransaction)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.lock_open, size: 20),
            label: Text(
              _isCreatingTransaction
                  ? 'Menyiapkan Pembayaran...'
                  : _isProcessing
                  ? 'Mengecek Status...'
                  : transaction == null
                  ? 'BAYAR SEKARANG'
                  : 'BUKA PEMBAYARAN LAGI',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),

        // Kalau transaksi sudah ada, sediakan cek status manual
        if (transaction != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (_isProcessing || _isCreatingTransaction)
                  ? null
                  : () => _checkStatus(transaction),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'SAYA SUDAH BAYAR / CEK STATUS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),
        Center(
          child: Text(
            MidtransService.isUsingLocalBackend
                ? 'Backend: ${MidtransService.backendBaseUrl} (lokal)'
                : 'Backend: ${MidtransService.backendBaseUrl}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(MidtransStatus status) {
    final bool paid = status.isPaid;
    final bool failed = status.isFailed;
    final MaterialColor color = paid
        ? Colors.green
        : failed
        ? Colors.red
        : Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            paid
                ? Icons.check_circle
                : failed
                ? Icons.error
                : Icons.hourglass_top,
            size: 18,
            color: color.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              failed
                  ? '${status.label}. Silakan buat pembayaran baru.'
                  : paid
                  ? 'Pembayaran lunas. Menyimpan ke buku kas...'
                  : '${status.label}. Jika sudah membayar, tekan "Cek Status". '
                        'Status Midtrans kadang butuh beberapa detik untuk berubah.',
              style: TextStyle(
                fontSize: 11,
                color: color.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool monospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: monospace ? 10 : 12,
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
