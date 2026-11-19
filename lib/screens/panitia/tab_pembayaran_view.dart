import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/kas_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/midtrans_payment_sheet.dart';

/// Tab Verifikasi Pembayaran & Penomoran Balap (Modul Milik Dika / Bendahara)
/// Bertanggung jawab atas:
/// 1. Pengecekan bukti bayar pendaftaran pembalap
/// 2. Verifikasi Lunas via Satu Atomic Transaction (Cek kuota, terbitkan nomor balap urut, catat kas masuk)
/// 3. Penolakan bukti transfer tidak valid dengan alasan wajib
/// 4. Opsi Pembayaran Midtrans Sandbox langsung otomatis masuk ke kas
class TabPembayaranView extends StatefulWidget {
  const TabPembayaranView({super.key});

  @override
  State<TabPembayaranView> createState() => _TabPembayaranViewState();
}

class _TabPembayaranViewState extends State<TabPembayaranView> {
  final KasService _kasService = KasService();
  String _selectedStatus = 'PENDING'; // 'PENDING' | 'PAID' | 'REJECTED'
  bool _isLoadingAction = false;

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dialog Konfirmasi Verifikasi Lunas Manual
  void _showVerifyDialog(Map<String, dynamic> reg) {
    final regId = reg['registrationId'] ?? '';
    final eventId = reg['eventId'] ?? '';
    final riderName = reg['riderName'] ?? 'Pembalap';
    final bikeName = reg['bikeName'] ?? 'Motor';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text('Verifikasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi pelunasan untuk pendaftaran berikut:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rider: $riderName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Motor: $bikeName', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('ID: $regId', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistem akan otomatis menerbitkan nomor balap urut lunas dan mencatat kas masuk komunitas.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoadingAction = true);
              try {
                final startNumber = await _kasService.verifyPaymentManual(
                  registrationId: regId,
                  eventId: eventId,
                );
                _showMessage('Berhasil diverifikasi! Nomor balap resmi: #$startNumber tercatat di Buku Kas.');
              } catch (e) {
                _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
              } finally {
                if (mounted) setState(() => _isLoadingAction = false);
              }
            },
            child: const Text('Verifikasi Lunas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Dialog Penolakan Bukti Transfer (Alasan Wajib)
  void _showRejectDialog(Map<String, dynamic> reg) {
    final regId = reg['registrationId'] ?? '';
    final riderName = reg['riderName'] ?? 'Pembalap';
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Tolak Bukti Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak bukti pembayaran untuk $riderName:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Nominal transfer kurang / struk tidak terbaca / bukti palsu...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '*Alasan penolakan wajib diisi agar pembalap dapat mengunggah ulang bukti yang sah.',
              style: TextStyle(fontSize: 10, color: Colors.red, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                _showMessage('Alasan penolakan tidak boleh kosong!', isError: true);
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isLoadingAction = true);
              try {
                await _kasService.rejectPaymentManual(
                  registrationId: regId,
                  rejectionReason: reason,
                );
                _showMessage('Bukti bayar ditolak. Alasan tersimpan untuk rider.');
              } catch (e) {
                _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
              } finally {
                if (mounted) setState(() => _isLoadingAction = false);
              }
            },
            child: const Text('Tolak Bukti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Membuka modal Midtrans Sandbox simulator untuk pendaftaran ini
  void _openMidtransSimulator(Map<String, dynamic> reg) {
    final regId = reg['registrationId'] ?? '';
    final eventId = reg['eventId'] ?? '';
    final riderName = reg['riderName'] ?? 'Pembalap';
    final eventTitle = reg['eventTitle'] ?? 'Event Balap DragHub';
    final amount = (reg['registrationFee'] as num?)?.toInt() ?? 350000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MidtransPaymentSheet(
        registrationId: regId,
        eventId: eventId,
        eventTitle: eventTitle,
        riderName: riderName,
        amount: amount,
        onPaymentSuccess: (startNumber) {
          _showMessage('Pembayaran Midtrans Sandbox Berhasil! Nomor: #$startNumber');
        },
      ),
    );
  }

  // Pengujian Cepat Midtrans Sandbox Langsung
  Future<void> _openDirectMidtransSandboxTest() async {
    setState(() => _isLoadingAction = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Harap login terlebih dahulu.');
      }
      final uid = currentUser.uid;

      // 1. Cari event yang berstatus PUBLISHED di Firestore
      final eventsSnap = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'PUBLISHED')
          .limit(1)
          .get();

      String eventId = '';
      String eventTitle = 'Kejuaraan DragHub Seri 01';
      int fee = 350000;

      if (eventsSnap.docs.isNotEmpty) {
        final ev = eventsSnap.docs.first;
        eventId = ev.id;
        final data = ev.data();
        eventTitle = data['title'] ?? eventTitle;
        fee = (data['registrationFee'] as num?)?.toInt() ?? fee;
      } else {
        // Cek apakah ada event apa pun di koleksi events
        final anyEventSnap = await FirebaseFirestore.instance.collection('events').limit(1).get();
        if (anyEventSnap.docs.isNotEmpty) {
          final ev = anyEventSnap.docs.first;
          eventId = ev.id;
          final data = ev.data();
          eventTitle = data['title'] ?? eventTitle;
          fee = (data['registrationFee'] as num?)?.toInt() ?? fee;
          // Pastikan statusnya PUBLISHED agar bisa dibayar
          try {
            await FirebaseFirestore.instance.collection('events').doc(eventId).update({
              'status': 'PUBLISHED',
            });
          } catch (_) {}
        } else {
          // Buat event published baru
          eventId = 'EVENT_IDW_2026';
          await FirebaseFirestore.instance.collection('events').doc(eventId).set({
            'eventId': eventId,
            'title': eventTitle,
            'location': 'Sirkuit NP Gelora Bung Tomo, Surabaya',
            'eventDate': FieldValue.serverTimestamp(),
            'imageUrl': 'https://placehold.co/600x400/png?text=DragHub+Event',
            'className': 'MATIC s.d 63mm',
            'vehicleType': 'MATIC',
            'maxPistonDiameterMm': 63.0,
            'bracketSeconds': 7.5,
            'registrationFee': fee,
            'quota': 30,
            'registeredCount': 0,
            'status': 'PUBLISHED',
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 2. Buat dokumen pendaftaran dengan userId akun Anda sendiri (memenuhi aturan security rules)
      final testRegId = 'REG_TEST_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final riderName = currentUser.displayName ?? 'Ferdi Rider (Tester)';

      await FirebaseFirestore.instance.collection('event_registrations').doc(testRegId).set({
        'registrationId': testRegId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'registrationFee': fee,
        'userId': uid,
        'bikeId': 'BIKE_VARIO_62',
        'riderName': riderName,
        'bikeName': 'Honda Vario 125',
        'vehicleType': 'MATIC',
        'pistonDiameterMm': 62.0,
        'paymentProofUrl': '',
        'paymentStatus': 'PENDING',
        'assignedStartNumber': null,
        'attendanceStatus': 'PENDING',
        'scrutineeringStatus': 'PENDING',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3. Tampilkan bottom sheet Midtrans Sandbox
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => MidtransPaymentSheet(
          registrationId: testRegId,
          eventId: eventId,
          eventTitle: eventTitle,
          riderName: riderName,
          amount: fee,
          onPaymentSuccess: (startNumber) {
            _showMessage('Pembayaran Midtrans Sandbox Sukses! Nomor: #$startNumber');
          },
        ),
      );
    } catch (e) {
      _showMessage('Gagal membuka simulasi Midtrans: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  // Dialog Preview Foto Bukti Transfer
  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Transfer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Gagal memuat gambar bukti transfer.'),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(24),
                        color: Colors.grey.shade100,
                        child: Text('Referensi Pembayaran:\n$imageUrl', textAlign: TextAlign.center),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Modul Bendahara
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'VERIFIKASI PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Modul Bendahara (Dika) • Nomor Balap & Kas Masuk',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: _openDirectMidtransSandboxTest,
                        icon: const Icon(Icons.flash_on, size: 14),
                        label: const Text('Tes Midtrans', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMaroon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet, size: 14, color: AppColors.primaryMaroon),
                            SizedBox(width: 4),
                            Text(
                              'BENDAHARA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryMaroon,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Selector Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabSelectorItem('PENDING', 'MENUNGGU'),
                    _buildTabSelectorItem('PAID', 'LUNAS (PAID)'),
                    _buildTabSelectorItem('REJECTED', 'DITOLAK'),
                  ],
                ),
              ),
            ),

            if (_isLoadingAction)
              const LinearProgressIndicator(color: AppColors.primaryMaroon, minHeight: 2),

            // Konten Antrean Pendaftaran
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _kasService.getAllRegistrationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                    );
                  }

                  final allDocs = snapshot.data ?? [];
                  final filteredDocs = allDocs
                      .where((d) => (d['paymentStatus'] ?? 'PENDING') == _selectedStatus)
                      .toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedStatus == 'PENDING'
                                  ? Icons.assignment_turned_in_outlined
                                  : (_selectedStatus == 'PAID' ? Icons.check_circle_outline : Icons.highlight_off),
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedStatus == 'PENDING'
                                  ? 'Tidak ada antrean verifikasi pembayaran.'
                                  : (_selectedStatus == 'PAID'
                                      ? 'Belum ada pendaftaran yang berstatus lunas.'
                                      : 'Belum ada bukti transfer yang ditolak.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (_selectedStatus == 'PENDING') ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _openDirectMidtransSandboxTest,
                                icon: const Icon(Icons.flash_on, size: 18),
                                label: const Text(
                                  '⚡ Coba Pembayaran Midtrans Sandbox Sekarang',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final reg = filteredDocs[index];
                      return _buildRegistrationCard(reg);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelectorItem(String status, String title) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.textDark : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> reg) {
    final riderName = reg['riderName'] ?? 'Pembalap';
    final bikeName = reg['bikeName'] ?? 'Motor';
    final vehicleType = reg['vehicleType'] ?? 'MATIC';
    final piston = (reg['pistonDiameterMm'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus = reg['paymentStatus'] ?? 'PENDING';
    final proofUrl = reg['paymentProofUrl'] ?? '';
    final startNumber = reg['assignedStartNumber'];
    final rejectionReason = reg['paymentRejectionReason'];
    final verifiedBy = reg['verifiedBy'];
    final isMidtrans = proofUrl.toString().contains('MIDTRANS');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Nama Pembalap & Nomor Balap
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riderName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$bikeName • $vehicleType (${piston.toStringAsFixed(1)}mm)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (startNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${startNumber.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'PENDING'
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: paymentStatus == 'PENDING'
                            ? Colors.orange.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      paymentStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: paymentStatus == 'PENDING'
                            ? Colors.orange.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),

            // Baris Bukti Pembayaran
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isMidtrans ? Icons.credit_card : Icons.receipt_long,
                      size: 16,
                      color: isMidtrans ? Colors.blue : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMidtrans ? 'Metode: Midtrans Sandbox' : 'Bukti Transfer Bank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMidtrans ? Colors.blue.shade800 : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (proofUrl.isNotEmpty && !isMidtrans)
                  GestureDetector(
                    onTap: () => _showProofImage(proofUrl),
                    child: const Text(
                      'Lihat Bukti Foto',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryMaroon,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),

            // Info jika ditolak
            if (paymentStatus == 'REJECTED' && rejectionReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alasan Penolakan: $rejectionReason',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Info verifikator jika lunas
            if (paymentStatus == 'PAID' && verifiedBy != null) ...[
              const SizedBox(height: 8),
              Text(
                'Diverifikasi oleh: $verifiedBy',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],

            // Tombol Aksi Verifikasi jika PENDING
            if (paymentStatus == 'PENDING') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showRejectDialog(reg),
                      child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () => _showVerifyDialog(reg),
                      child: const Text('Verifikasi Lunas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tombol Tambahan Simulasi Midtrans Sandbox
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade200),
                    backgroundColor: Colors.blue.shade50.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openMidtransSimulator(reg),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Simulasi Bayar via Midtrans Sandbox', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
