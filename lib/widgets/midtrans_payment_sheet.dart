import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/midtrans_service.dart';
import '../theme/app_colors.dart';

/// Bottom Sheet Interaktif Midtrans Sandbox Payment Gateway
/// Mengakomodasi kebutuhan: Pembalap / Tester membayar biaya pendaftaran via Midtrans Sandbox
/// Hasil pembayaran langsung otomatis masuk ke kas_transactions & terbit nomor balap.
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

  String _selectedMethod = 'QRIS'; // 'QRIS', 'BCA_VA', 'MANDIRI_BILL', 'BNI_VA', 'BRI_VA'
  late String _currentVaNumber;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _orderId = MidtransService.generateOrderId(widget.registrationId);
    _currentVaNumber = MidtransService.generateVirtualAccount('BCA');
  }

  void _onSelectMethod(String method) {
    setState(() {
      _selectedMethod = method;
      if (method == 'BCA_VA') {
        _currentVaNumber = MidtransService.generateVirtualAccount('BCA');
      } else if (method == 'BNI_VA') {
        _currentVaNumber = MidtransService.generateVirtualAccount('BNI');
      } else if (method == 'BRI_VA') {
        _currentVaNumber = MidtransService.generateVirtualAccount('BRI');
      } else if (method == 'MANDIRI_BILL') {
        _currentVaNumber = MidtransService.generateVirtualAccount('MANDIRI');
      }
    });
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

  Future<void> _handleSimulateSuccess() async {
    setState(() => _isProcessing = true);
    try {
      final startNumber = await _midtransService.payWithMidtransSandbox(
        registrationId: widget.registrationId,
        eventId: widget.eventId,
        amount: widget.amount,
        paymentChannel: _selectedMethod,
        orderId: _orderId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Tutup bottom sheet

      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(startNumber);
      }

      // Dialog Notifikasi Sukses
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
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
                  color: AppColors.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryMaroon),
                ),
                child: Text(
                  '#${startNumber.toString().padLeft(3, '0')}',
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK, Mantap!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran gagal: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
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
        child: Column(
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

            // Header Midtrans Sandbox
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
                      child: const Icon(Icons.payment, color: Colors.blue, size: 20),
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
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text(
                    'SANDBOX MODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Event', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(widget.eventTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pembalap', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(widget.riderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order ID', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(_orderId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),

            // Pilihan Metode Pembayaran
            const Text(
              'Pilih Metode Pembayaran Sandbox:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMethodChip('QRIS', '⚡ QRIS / GoPay'),
                _buildMethodChip('BCA_VA', '🏦 BCA VA'),
                _buildMethodChip('MANDIRI_BILL', '🏦 Mandiri Bill'),
                _buildMethodChip('BNI_VA', '🏦 BNI VA'),
                _buildMethodChip('BRI_VA', '🏦 BRI VA'),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilan Instruksi sesuai metode
            if (_selectedMethod == 'QRIS') _buildQrisView() else _buildVaView(),

            const SizedBox(height: 24),

            // Tombol Simulasi Pembayaran Sukses
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _handleSimulateSuccess,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on, size: 20),
                label: Text(
                  _isProcessing ? 'Memproses ke Buku Kas...' : 'Simulasi Bayar Sukses (Sandbox)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Mode Testing Sandbox • Pembayaran akan langsung mengupdate Firestore.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(String method, String label) {
    final isSelected = _selectedMethod == method;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onSelectMethod(method),
      selectedColor: AppColors.primaryMaroon.withOpacity(0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryMaroon : AppColors.textDark,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryMaroon : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildQrisView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 120, color: AppColors.textDark),
                const SizedBox(height: 4),
                Text(
                  'QRIS STANDAR PEMBAYARAN NASIONAL',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buka aplikasi GoPay / OVO / Dana / Mobile Banking, scan QR di atas untuk simulasi bayar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVaView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nomor Virtual Account ($_selectedMethod):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _currentVaNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin!'), duration: Duration(seconds: 1)),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy, size: 14, color: AppColors.primaryMaroon),
                    SizedBox(width: 4),
                    Text('Salin', style: TextStyle(fontSize: 11, color: AppColors.primaryMaroon, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentVaNumber,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textDark),
                ),
                const Icon(Icons.account_balance, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Transfer tepat sejumlah nominal ke nomor VA di atas. Transaksi simulasi akan otomatis terverifikasi.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
