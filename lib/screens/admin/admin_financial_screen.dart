import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';

class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() => _AdminFinancialScreenState();
}

class _AdminFinancialScreenState extends State<AdminFinancialScreen> {
  final int _adminNavIndex = 1; // 1 = Finansial
  int _selectedTab = 0; // 0 = Menunggu, 1 = Disetujui, 2 = Ditolak

  // FUNGSI DINAMIS: Mengupdate status pembayaran di Firestore
  Future<void> _updatePaymentStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('payments').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal update status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAdminAppBar(),
      // 1. STREAM BUILDER UTAMA: Menarik data koleksi 'payments'
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
          }

          final List<DocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : [];
          
          int pendingCount = 0;
          int approvedCount = 0;
          int rejectedCount = 0;
          double totalVerifiedAmount = 0;

          List<DocumentSnapshot> pendingList = [];
          List<DocumentSnapshot> approvedList = [];
          List<DocumentSnapshot> rejectedList = [];

          // 2. MENGHITUNG STATISTIK & MEMISAHKAN DATA BERDASARKAN STATUS
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'PENDING';
            
            if (status == 'PENDING') {
              pendingCount++;
              pendingList.add(doc);
            } else if (status == 'APPROVED') {
              approvedCount++;
              approvedList.add(doc);
              totalVerifiedAmount += (data['amount'] ?? 0);
            } else if (status == 'REJECTED') {
              rejectedCount++;
              rejectedList.add(doc);
            }
          }

          // Format Uang Dinamis (Tanpa package intl agar aman)
          String verifiedAmountStr = totalVerifiedAmount > 1000000 
              ? 'Rp ${(totalVerifiedAmount / 1000000).toStringAsFixed(1)}M' 
              : 'Rp ${totalVerifiedAmount.toStringAsFixed(0)}';
          if (totalVerifiedAmount == 0) verifiedAmountStr = 'Rp 0';

          // List mana yang ditampilkan tergantung Tab yang diklik
          List<DocumentSnapshot> activeList = _selectedTab == 0 ? pendingList : (_selectedTab == 1 ? approvedList : rejectedList);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleHeader(),
                const SizedBox(height: 20),
                _buildSummaryCards(verifiedAmountStr, approvedCount, pendingCount, rejectedCount),
                const SizedBox(height: 20),
                _buildTabSelector(pendingCount, approvedCount, rejectedCount),
                const SizedBox(height: 24),
                _buildQueueHeader(),
                const SizedBox(height: 12),
                _buildVerificationQueue(activeList),
                const SizedBox(height: 24),
                if (_selectedTab == 0 && approvedList.isNotEmpty) _buildHistorySection(approvedList.first),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildAdminBottomNav(),
    );
  }

  // --- KOMPONEN UI STATIS HEADER ---
  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, 
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.flag, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('APEX DRAG', style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('OFFICIAL PORTAL', style: TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          )
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryMaroon, child: Icon(Icons.person, color: Colors.white, size: 18)),
        ),
      ],
    );
  }

  Widget _buildRoleHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: const [
                  Icon(Icons.verified_user_outlined, color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text('VERIFIKATOR KEUANGAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('SINKRON MUTASI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildBankStatus('BCA'),
                const SizedBox(width: 8),
                _buildBankStatus('MANDIRI'),
                const SizedBox(width: 8),
                _buildBankStatus('QRIS'),
              ],
            ),
            const Text('LIVE SYNC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
          ],
        )
      ],
    );
  }

  Widget _buildBankStatus(String bank) {
    return Row(
      children: [
        Text(bank, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon)),
        const SizedBox(width: 4),
        const Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF2E7D32)),
      ],
    );
  }

  // --- UI DINAMIS BERDASARKAN STREAM ---
  Widget _buildSummaryCards(String verifiedAmount, int approvedCount, int pendingCount, int rejectedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'TERVERIFIKASI', icon: Icons.account_balance_wallet_outlined,
            value: verifiedAmount, subtitle: '$approvedCount Transaksi',
            isActive: _selectedTab == 1, indicatorColor: AppColors.primaryMaroon
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'ANTREAN', icon: Icons.hourglass_top,
            value: '$pendingCount', subtitle: 'Bukti Bayar',
            isActive: _selectedTab == 0, bottomText: 'MENUNGGU\nAUDIT'
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'DITOLAK', icon: Icons.cancel_outlined,
            value: '$rejectedCount', subtitle: 'Perlu\nKlarifikasi',
            isActive: _selectedTab == 2, indicatorColor: Colors.red
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required IconData icon, required String value, required String subtitle, required bool isActive, Color? indicatorColor, String? bottomText}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryMaroon : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? null : Border.all(color: AppColors.borderLight),
        boxShadow: isActive ? [BoxShadow(color: AppColors.primaryMaroon.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: isActive ? Colors.white70 : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isActive ? Colors.white70 : AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isActive ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 9, color: isActive ? Colors.white70 : AppColors.textMuted, height: 1.2)),
          const SizedBox(height: 12),
          if (isActive && bottomText != null)
            Row(
              children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(bottomText, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
              ],
            )
          else if (!isActive && indicatorColor != null)
            Container(width: 24, height: 3, decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildTabSelector(int pendingCount, int approvedCount, int rejectedCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Expanded(child: _buildTabItem(0, 'MENUNGGU', pendingCount)),
          Expanded(child: _buildTabItem(1, 'DISETUJUI', approvedCount)),
          Expanded(child: _buildTabItem(2, 'DITOLAK', rejectedCount)),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, int count) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSelected ? AppColors.primaryMaroon : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppColors.textMuted)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
              decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.segmentBackground, borderRadius: BorderRadius.circular(10)), 
              child: Text('$count', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textDark))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueHeader() {
    String title = _selectedTab == 0 ? 'Antrean Verifikasi' : (_selectedTab == 1 ? 'Transaksi Disetujui' : 'Transaksi Ditolak');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primaryMaroon, size: 16),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(4)),
          child: const Text('LIVE DB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
        ),
      ],
    );
  }

  Widget _buildVerificationQueue(List<DocumentSnapshot> activeList) {
    if (activeList.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
        child: const Text('Tidak ada data transaksi di kategori ini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
      );
    }

    return Column(
      children: activeList.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final docId = doc.id;
        
        // Format angka ke format uang indonesia tanpa package tambahan
        final amountVal = data['amount'] ?? 0;
        final amountFormatted = 'Rp ${amountVal.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".")}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildQueueCard(
            name: data['racerName'] ?? 'Anonim', startNumber: data['startNumber'] ?? '#---',
            className: data['className'] ?? 'Kelas Balap',
            paymentMethod: data['paymentMethod'] ?? 'TRANSFER BANK', refNumber: data['refNumber'],
            amount: amountFormatted, amountStatus: data['amountStatus'] ?? 'REGISTRASI',
            statusColor: _getStatusColor(data['status'] ?? 'PENDING'),
            isAutoMatched: data['isAutoMatched'] ?? false,
            warningMessage: data['warningMessage'],
            actions: _buildActionsForStatus(data['status'] ?? 'PENDING', docId, data['isAutoMatched'] ?? false, data['warningMessage'] != null),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'APPROVED') return const Color(0xFF2E7D32);
    if (status == 'REJECTED') return Colors.red;
    return AppColors.textMuted;
  }

  Widget _buildQueueCard({
    required String name, required String startNumber, required String className, required String paymentMethod, String? refNumber,
    required String amount, required String amountStatus, Color statusColor = AppColors.textMuted,
    bool isAutoMatched = false, String? warningMessage, required Widget actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
                child: const Icon(Icons.receipt, color: AppColors.textMuted, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFDF2F2), borderRadius: BorderRadius.circular(4)),
                          child: Text(startNumber, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(className, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(paymentMethod, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                        if (refNumber != null) ...[
                          const Text('  •  Ref: ', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          Text(refNumber, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ],
                        if (isAutoMatched) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                            child: const Text('KODE UNIK COCOK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon)),
                  const SizedBox(height: 4),
                  Text(amountStatus, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1.0)),
                ],
              )
            ],
          ),
          
          if (warningMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(warningMessage, style: const TextStyle(fontSize: 9, color: AppColors.textDark, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          actions,
        ],
      ),
    );
  }

  // --- TOMBOL AKSI DINAMIS MENGHUBUNGI FIRESTORE ---
  Widget _buildActionsForStatus(String status, String docId, bool isAutoMatched, bool hasWarning) {
    if (status == 'APPROVED') {
      return OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36), backgroundColor: const Color(0xFFE8F5E9), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        icon: const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
        label: const Text('TRANSAKSI TELAH DISETUJUI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), letterSpacing: 0.5)),
      );
    } else if (status == 'REJECTED') {
      return OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36), backgroundColor: const Color(0xFFFDF2F2), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        icon: const Icon(Icons.cancel, size: 14, color: Colors.red),
        label: const Text('TRANSAKSI TELAH DITOLAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 0.5)),
      );
    } else {
      // Pending actions
      if (isAutoMatched) return _buildActionsInstant(docId);
      if (hasWarning) return _buildActionsWarning(docId);
      return _buildActionsNormal(docId);
    }
  }

  Widget _buildActionsNormal(String docId) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.segmentBackground, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textDark),
            label: const Text('LIHAT STRUK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => _updatePaymentStatus(docId, 'REJECTED'),
            style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFFDF2F2), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.close, size: 12, color: AppColors.primaryMaroon),
            label: const Text('TOLAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => _updatePaymentStatus(docId, 'APPROVED'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.verified, size: 12, color: Colors.white),
            label: const Text('SETUJUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsInstant(String docId) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.segmentBackground, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.receipt, size: 12, color: AppColors.textDark),
            label: const Text('STRUK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: ElevatedButton.icon(
            onPressed: () => _updatePaymentStatus(docId, 'APPROVED'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.bolt, size: 14, color: Colors.white),
            label: const Text('CEPAT SETUJUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsWarning(String docId) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.segmentBackground, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textDark),
            label: const Text('AUDIT SLIP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.segmentBackground, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.textDark),
            label: const Text('TANYA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () => _updatePaymentStatus(docId, 'APPROVED'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: const Text('SETUJUI\nOVERRIDE', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(DocumentSnapshot lastDoc) {
    final data = lastDoc.data() as Map<String, dynamic>;
    final amountVal = data['amount'] ?? 0;
    final amountFormatted = 'Rp ${amountVal.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".")}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.history, color: AppColors.textMuted, size: 16),
                SizedBox(width: 8),
                Text('Riwayat Terakhir Disetujui', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              ],
            ),
            const Text('BARU SAJA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['racerName'] ?? 'Anonim'} (${data['startNumber'] ?? '#---'})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(data['paymentMethod'] ?? 'Transfer', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountFormatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  const Text('SELESAI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  // --- BOTTOM NAV ADMIN ---
  Widget _buildAdminBottomNav() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, Icons.view_sidebar_outlined, 'EVENT'),
          _buildNavIcon(1, Icons.request_quote, 'FINANSIAL'),
          _buildNavIcon(2, Icons.timer_outlined, 'TIMING'),
          _buildNavIcon(3, Icons.assignment_ind_outlined, 'PETUGAS'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isSelected = _adminNavIndex == index;
    final color = isSelected ? AppColors.primaryMaroon : AppColors.textMuted;
    
    return GestureDetector(
      onTap: () {
        if (index == 1) return;
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: color)),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle))
          ]
        ],
      ),
    );
  }
}