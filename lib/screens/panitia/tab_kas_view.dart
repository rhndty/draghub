import 'package:flutter/material.dart';
import '../../models/kas_model.dart';
import '../../services/kas_service.dart';
import '../../theme/app_colors.dart';

/// Tab Buku Kas & Riwayat Transaksi Komunitas (Modul Milik Dika / Bendahara)
/// Sesuai PRD v1.4 & Permintaan Khusus:
/// - Hanya Panitia (Bendahara, Ketua, Wakil, Sekretaris) yang bisa melihat riwayat transaksi.
/// - User / Anggota biasa TIDAK BISA MELIHAT (Akses Ditolak).
/// - Khusus Bendahara: Memiliki akses penuh (bisa input mutasi kas masuk/keluar baru).
class TabKasView extends StatefulWidget {
  const TabKasView({super.key});

  @override
  State<TabKasView> createState() => _TabKasViewState();
}

class _TabKasViewState extends State<TabKasView> {
  final KasService _kasService = KasService();

  String _userRole = 'loading'; // 'loading', 'anggota', 'bendahara', 'ketua', etc.
  String _selectedCategory = 'SEMUA';
  String _selectedType = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await _kasService.getCurrentUserRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  bool get _isPanitia => [
        'bendahara',
        'ketua',
        'wakil',
        'sekretaris',
        'super_admin',
        'verifikator',
        'race_director',
        'race_control',
      ].contains(_userRole);

  bool get _isBendahara => _userRole == 'bendahara' || _userRole == 'super_admin';

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

  String _formatNumber(int number) {
    final digits = number.abs().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write('.');
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return number < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }

  // Dialog / Modal Form Tambah Mutasi Kas Baru (Khusus Bendahara)
  void _openAddKasDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String type = 'MASUK';
    String category = 'IURAN_ANGGOTA';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CATAT MUTASI KAS BARU',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tipe Kas (Masuk / Keluar)
                  const Text('Tipe Arus Kas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('UANG MASUK (+)')),
                          selected: type == 'MASUK',
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: type == 'MASUK' ? Colors.green.shade900 : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: isSubmitting ? null : (val) => setModalState(() => type = 'MASUK'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('UANG KELUAR (-)')),
                          selected: type == 'KELUAR',
                          selectedColor: Colors.red.shade100,
                          labelStyle: TextStyle(
                            color: type == 'KELUAR' ? Colors.red.shade900 : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: isSubmitting ? null : (val) => setModalState(() => type = 'KELUAR'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Judul Transaksi
                  const Text('Keterangan / Judul:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      hintText: type == 'MASUK' ? 'Contoh: Iuran Bulanan Anggota November' : 'Contoh: Sewa Sirkuit NP Bung Tomo',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kategori
                  const Text('Kategori Kas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PENDAFTARAN_EVENT', child: Text('Pendaftaran Event')),
                      DropdownMenuItem(value: 'IURAN_ANGGOTA', child: Text('Iuran Anggota')),
                      DropdownMenuItem(value: 'SEWA_SIRKUIT', child: Text('Sewa Sirkuit')),
                      DropdownMenuItem(value: 'OPERASIONAL', child: Text('Operasional / Logistik Paddock')),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            if (val != null) setModalState(() => category = val);
                          },
                  ),
                  const SizedBox(height: 14),

                  // Nominal Uang (Rupiah)
                  const Text('Nominal (Rp):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '500000',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Catatan Opsional
                  const Text('Catatan Tambahan (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Nomor kwitansi / catatan panitia...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final amount = int.tryParse(amountController.text.trim());

                              if (title.isEmpty) {
                                _showMessage('Judul transaksi wajib diisi!', isError: true);
                                return;
                              }
                              if (amount == null || amount <= 0) {
                                _showMessage('Nominal uang harus angka valid dan lebih dari 0!', isError: true);
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await _kasService.recordManualKasTransaction(
                                  title: title,
                                  category: category,
                                  type: type,
                                  amount: amount,
                                  notes: notesController.text.trim(),
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _showMessage('Mutasi kas berhasil disimpan!');
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                _showMessage('Gagal menyimpan mutasi kas: $e', isError: true);
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Mutasi Kas',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Dialog Hapus Transaksi (Khusus Bendahara jika salah input)
  void _confirmDeleteTransaction(KasModel kas) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus Transaksi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apakah Anda yakin ingin menghapus catatan kas ini?'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.segmentBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kas.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kas.formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: kas.isMasuk ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Kategori: ${kas.category}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      Text('ID: ${kas.transactionId}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await _kasService.deleteKasTransaction(kas.transactionId);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _showMessage('Catatan kas berhasil dihapus!');
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          if (ctx.mounted) {
                            showDialog(
                              context: context,
                              builder: (errCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Gagal Menghapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Server Firebase menolak operasi penghapusan:', style: TextStyle(fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text(
                                        '$e',
                                        style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Solusi: Pastikan izin "delete" untuk koleksi kas_transactions telah diizinkan (allow delete: if ...) di tab Rules Firebase Console.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(errCtx), child: const Text('Tutup')),
                                ],
                              ),
                            );
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Hapus Permanen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilan saat masih membaca role pengguna
    if (_userRole == 'loading') {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon)),
      );
    }

    // 2. PROTEKSI RBAC: User / Anggota Biasa Dilarang Mengakses Riwayat Transaksi Kas
    if (!_isPanitia) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_person_outlined, size: 64, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AKSES DITOLAK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Riwayat transaksi dan Buku Kas Komunitas bersifat rahasia dan hanya dapat diakses oleh Panitia (Bendahara & Pengurus).\n\nAkun Anda terdaftar sebagai: ${_userRole.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryMaroon,
                      side: const BorderSide(color: AppColors.primaryMaroon),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali ke Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Tampilan Buku Kas Lengkap bagi Panitia
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _isBendahara
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryMaroon,
              onPressed: _openAddKasDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Catat Kas Baru',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header Panitia
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BUKU KAS KOMUNITAS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        _isBendahara
                            ? 'Modul Bendahara (Dika) • Kelola Arus Kas'
                            : 'Monitoring Keuangan Panitia (${_userRole.toUpperCase()})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isBendahara ? AppColors.primaryMaroon.withOpacity(0.1) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isBendahara ? 'FULL ACCESS' : 'READ-ONLY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _isBendahara ? AppColors.primaryMaroon : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Ringkasan Finansial Realtime
            StreamBuilder<Map<String, dynamic>>(
              stream: _kasService.getFinancialSummaryStream(),
              builder: (context, snapshot) {
                final summary = snapshot.data ?? {
                  'totalSaldo': 0,
                  'totalMasuk': 0,
                  'totalKeluar': 0,
                  'transactionCount': 0,
                };
                final totalSaldo = summary['totalSaldo'] as int;
                final totalMasuk = summary['totalMasuk'] as int;
                final totalKeluar = summary['totalKeluar'] as int;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Card Saldo Bersih Utama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B0E17), Color(0xFF8B1522)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryMaroon.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL SALDO KAS KOMUNITAS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatNumber(totalSaldo),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${summary['transactionCount']} Catatan Transaksi Terverifikasi',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Card Masuk & Keluar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_downward, color: Colors.green.shade700, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'TOTAL MASUK',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatNumber(totalMasuk),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_upward, color: Colors.red.shade700, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'TOTAL KELUAR',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatNumber(totalKeluar),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Baris Filter Kategori & Tipe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('SEMUA', 'Semua Kategori', _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('PENDAFTARAN_EVENT', 'Pendaftaran', _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('IURAN_ANGGOTA', 'Iuran', _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('SEWA_SIRKUIT', 'Sewa Sirkuit', _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('OPERASIONAL', 'Operasional', _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                  ],
                ),
              ),
            ),

            // Daftar Riwayat Mutasi Kas
            Expanded(
              child: StreamBuilder<List<KasModel>>(
                stream: _kasService.getKasTransactionsStream(
                  category: _selectedCategory,
                  type: _selectedType,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                            const SizedBox(height: 12),
                            const Text(
                              'Kendala Sinkronisasi Buku Kas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Penyebab Umum: Izin Rules di Firebase Console memblokir baca/tulis koleksi kas_transactions, atau akun Anda belum memiliki role \'bendahara\' di Firestore.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat transaksi kas pada filter ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _buildKasCard(item);
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

  Widget _buildFilterChip(String key, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryMaroon.withOpacity(0.12),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
      ),
      side: BorderSide(color: isSelected ? AppColors.primaryMaroon : AppColors.borderLight),
      onSelected: (_) => onSelect(key),
    );
  }

  Widget _buildKasCard(KasModel kas) {
    final isMasuk = kas.isMasuk;
    final formattedDate =
        '${kas.transactionDate.day}/${kas.transactionDate.month}/${kas.transactionDate.year} ${kas.transactionDate.hour.toString().padLeft(2, '0')}:${kas.transactionDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Masuk / Keluar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMasuk ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMasuk ? Icons.call_received : Icons.call_made,
              color: isMasuk ? Colors.green.shade700 : Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Detail Keterangan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kas.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.segmentBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        kas.category.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (kas.paymentMethod != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Metode: ${kas.paymentMethod}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kas.paymentMethod!.contains('MIDTRANS') ? Colors.blue.shade800 : AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Dicatat oleh: ${kas.recordedByName}',
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),

          // Nominal & Tombol Hapus (Khusus Bendahara)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                kas.formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isMasuk ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              if (_isBendahara) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDeleteTransaction(kas),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 13, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Hapus',
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
