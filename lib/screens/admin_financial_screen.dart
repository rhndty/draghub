import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() => _AdminFinancialScreenState();
}

class _AdminFinancialScreenState extends State<AdminFinancialScreen> {
  int _adminNavIndex = 1; // 1 = Finansial

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAdminAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleHeader(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildTabSelector(),
            const SizedBox(height: 24),
            _buildQueueHeader(),
            const SizedBox(height: 12),
            _buildVerificationQueue(),
            const SizedBox(height: 24),
            _buildHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. APP BAR KHUSUS ADMIN ---
  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('ADMIN', style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text('VERIFIKATOR KEUANGAN', style: TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          )
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
          ),
          child: Row(
            children: const [
              Icon(Icons.shield_outlined, color: AppColors.primaryMaroon, size: 14),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: AppColors.primaryMaroon, size: 14),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryMaroon, child: Icon(Icons.person, color: Colors.white, size: 18)),
        ),
      ],
    );
  }

  // --- 2. HEADER PERAN & STATUS MUTASI ---
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
            const Text('10:42:19 WIB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
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

  // --- 3. KARTU RINGKASAN (SUMMARY CARDS) ---
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'TERVERIFIKASI', 
            icon: Icons.account_balance_wallet_outlined,
            value: 'Rp 96.2M', 
            subtitle: '148 Transaksi',
            isActive: false,
            indicatorColor: AppColors.primaryMaroon
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'ANTREAN', 
            icon: Icons.hourglass_top,
            value: '12', 
            subtitle: 'Bukti Bayar',
            isActive: true,
            bottomText: 'MENUNGGU\nAUDIT'
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'DITOLAK', 
            icon: Icons.cancel_outlined,
            value: '2', 
            subtitle: 'Perlu\nKlarifikasi',
            isActive: false,
            indicatorColor: Colors.red
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

  // --- 4. TAB SELECTOR ANTARA STATUS ---
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('MENUNGGU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Text('12', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: RichText(text: const TextSpan(style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted), children: [TextSpan(text: 'DISETUJUI  '), TextSpan(text: '148', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900))])),
            ),
          ),
          Expanded(
            child: Center(
              child: RichText(text: const TextSpan(style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted), children: [TextSpan(text: 'DITOLAK  '), TextSpan(text: '2', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900))])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.receipt_long_outlined, color: AppColors.primaryMaroon, size: 16),
            SizedBox(width: 8),
            Text('Antrean Verifikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(4)),
          child: const Text('BATCH #04', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 1.0)),
        ),
      ],
    );
  }

  // --- 5. DAFTAR ANTREAN (QUEUE LIST) ---
  Widget _buildVerificationQueue() {
    return Column(
      children: [
        // Kartu 1: Normal
        _buildQueueCard(
          name: 'Raka Aditia', startNumber: '#402',
          className: 'Bebek 200cc TU Paddock',
          paymentMethod: 'BCA TRANSFER', refNumber: '8820419',
          amount: 'Rp 700.000', amountStatus: 'REGISTRASI FINAL',
          actions: _buildActionsNormal(),
        ),
        const SizedBox(height: 12),
        // Kartu 2: Auto Matched (Instant)
        _buildQueueCard(
          name: 'Dimas Arya', startNumber: '#105',
          className: 'Sport 2T 155cc Frame STD',
          paymentMethod: 'QRIS APEX INSTANT',
          amount: 'Rp 700.105', amountStatus: 'AUTO-MATCHED', statusColor: const Color(0xFF2E7D32),
          isAutoMatched: true,
          actions: _buildActionsInstant(),
        ),
        const SizedBox(height: 12),
        // Kartu 3: Anomaly (Warning)
        _buildQueueCard(
          name: 'Bagas Saputra', startNumber: '#312',
          className: 'FFA 350cc Non Matic',
          paymentMethod: 'MANDIRI TRANSFER', refNumber: '991204',
          amount: 'Rp 850.000', amountStatus: 'FFA CLASS TIER',
          warningMessage: 'Nama pengirim di rekening (HENDRA SAPUTRA) berbeda dengan data KTA IMI (BAGAS SAPUTRA).',
          actions: _buildActionsWarning(),
        ),
      ],
    );
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
              // Thumbnail Struk
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
                child: const Icon(Icons.receipt, color: AppColors.textMuted, size: 24), // Placeholder untuk struk
              ),
              const SizedBox(width: 12),
              // Info Pembalap & Kelas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
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
              // Jumlah Transfer
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
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 9, color: AppColors.textDark, height: 1.4),
                        children: [
                          const TextSpan(text: 'Perhatian: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: warningMessage.split('(HENDRA SAPUTRA)')[0]),
                          const TextSpan(text: '(HENDRA SAPUTRA)', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryMaroon)),
                          TextSpan(text: warningMessage.split('(HENDRA SAPUTRA)')[1].split('(BAGAS SAPUTRA)')[0]),
                          const TextSpan(text: '(BAGAS SAPUTRA).', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
                        ],
                      ),
                    ),
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

  // Baris Tombol Aksi - Normal
  Widget _buildActionsNormal() {
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
            onPressed: () {},
            style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFFDF2F2), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.close, size: 12, color: AppColors.primaryMaroon),
            label: const Text('TOLAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.verified, size: 12, color: Colors.white),
            label: const Text('SETUJUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ],
    );
  }

  // Baris Tombol Aksi - Instan (Auto-Match)
  Widget _buildActionsInstant() {
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
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.bolt, size: 14, color: Colors.white),
            label: const Text('CEPAT SETUJUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          ),
        ),
      ],
    );
  }

  // Baris Tombol Aksi - Peringatan
  Widget _buildActionsWarning() {
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
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: const Text('SETUJUI\nOVERRIDE', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  // --- 6. RIWAYAT TERAKHIR ---
  Widget _buildHistorySection() {
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
            const Text('2 MENIT LALU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
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
                    children: const [
                      Text('Fandi Ahmad (#208)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('BCA Auto-Clear', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Rp 700.000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('5 MNT LALU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

 
}