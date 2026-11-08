import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';

class PanitiaHomeScreen extends StatefulWidget {
  const PanitiaHomeScreen({super.key});

  @override
  State<PanitiaHomeScreen> createState() => _PanitiaHomeScreenState();
}

class _PanitiaHomeScreenState extends State<PanitiaHomeScreen> {
  int _selectedTabIndex = 0; // 0: Pembayaran, 1: Telemetri, 2: Event
  int _bottomNavIndex = 0;

  // Controllers untuk Form Input Telemetri
  final TextEditingController _startNumberController = TextEditingController();
  final TextEditingController _reactionTimeController = TextEditingController();
  final TextEditingController _elapsedTimeController = TextEditingController();

  String _selectedLane = 'LANE 01';
  String _selectedStage = 'QUALIFYING';
  String? _selectedEventId;
  bool _isSavingTime = false;

  @override
  void dispose() {
    _startNumberController.dispose();
    _reactionTimeController.dispose();
    _elapsedTimeController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Portal Panitia'),
        content: const Text('Apakah Anda yakin ingin mengakhiri sesi ofisial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showPaymentProofDialog(BuildContext context, String? url, String startNumber, String ownerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bukti Transfer Pendaftaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$startNumber • $ownerName',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (url != null && url.startsWith('http'))
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.segmentBackground,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 8),
                              const Text('Gagal memuat gambar bukti transfer.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(url, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.blue)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.segmentBackground,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('Belum ada tautan gambar bukti transfer.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            if (url != null && url.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(url, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _bottomNavIndex == 3
          ? const LeaderboardScreen()
          : SafeArea(
              child: Column(
                children: [
                  // Header Panitia
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
                    child: Column(
                      children: [
                        _buildTopHeader(),
                        const SizedBox(height: 16),
                        _buildPanitiaStatusBadge(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Konten Tab Aktif
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildCurrentTabView(),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ===========================================================================
  // 1. HEADER & STATUS BADGE PANITIA
  // ===========================================================================

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: AppColors.primaryMaroon, size: 26),
            SizedBox(width: 8),
            Text(
              'DragHub Official',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _handleLogout,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.segmentBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.logout, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'Keluar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanitiaStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMaroon.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primaryMaroon,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANITIA & OFISIAL BALAP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryMaroon,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Akses Penuh: Verifikasi Pembayaran & Kendaraan, Telemetri, Kontrol Event',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text(
                  'AKTIF',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCurrentTabView() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPembayaranTabView();
      case 1:
        return _buildInputTelemetriTabView();
      case 2:
        return _buildKontrolEventTabView();
      default:
        return _buildPembayaranTabView();
    }
  }

  // ===========================================================================
  // 2. TAB 1: VERIFIKASI PEMBAYARAN & KENDARAAN (Koleksi `registrations`)
  // ===========================================================================

  Widget _buildPembayaranTabView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.payments_outlined,
          'VERIFIKASI PEMBAYARAN & KENDARAAN',
          'VALIDASI PESERTA',
        ),
        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('registrations').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCard('Belum ada data pendaftaran di sistem.');
            }

            final docs = snapshot.data!.docs;

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final regId = doc.id;
                return _buildRegistrationCard(data, regId);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> data, String regId) {
    final startNum = data['assignedStartNumber'] ?? '#---';
    final bikeBrand = data['bikeBrand'] ?? '';
    final bikeModel = data['bikeModel'] ?? '';
    final bikeName = '$bikeBrand $bikeModel'.trim().isEmpty ? 'Motor Balap' : '$bikeBrand $bikeModel'.trim();
    final cc = data['engineCc'] != null ? '${data['engineCc']}cc' : '-';
    final paymentStatus = data['paymentStatus'] ?? 'PENDING';
    final isPaid = paymentStatus == 'PAID';
    final paymentProofUrl = data['paymentProofUrl'] as String?;
    final userId = data['userId'] ?? '';
    final eventId = data['eventId'] ?? '';
    final classId = data['classId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? Colors.green.shade300 : AppColors.borderLight,
          width: isPaid ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Kartu: Nomor Start & Status Pembayaran
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaroon,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        startNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUS PEMBAYARAN',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        Text(
                          isPaid ? 'LUNAS (VERIFIED)' : 'MENUNGGU VERIFIKASI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPaid ? Colors.green.shade300 : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.pending_actions,
                        size: 13,
                        color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPaid ? 'PAID' : 'PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // 2. IDENTITAS PEMILIK & IDENTITAS EVENT
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identitas Pemilik
                _buildOwnerInfoSection(userId, startNum),
                const SizedBox(height: 12),

                // Identitas Event & Kelas
                _buildEventAndClassSection(eventId, classId),
                const SizedBox(height: 14),

                // 3. KENDARAAN YANG DIDAFTARKAN
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.segmentBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.two_wheeler, color: AppColors.primaryMaroon, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KENDARAAN TERDAFTAR',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bikeName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kapasitas Mesin: $cc',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryMaroon),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Tombol Pratinjau Bukti Transfer & Konfirmasi Pembayaran
                Row(
                  children: [
                    // Tombol Lihat Bukti Pembayaran
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () => _showPaymentProofDialog(
                          context,
                          paymentProofUrl,
                          startNum,
                          bikeName,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.receipt_long, size: 16, color: AppColors.primaryMaroon),
                        label: const Text(
                          'Bukti Bayar',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Aksi Verifikasi Lunas / Batal
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newStatus = isPaid ? 'PENDING' : 'PAID';
                          await FirebaseFirestore.instance
                              .collection('registrations')
                              .doc(regId)
                              .update({
                            'paymentStatus': newStatus,
                            'verificationStatus': isPaid ? 'PENDING' : 'VERIFIED',
                          });
                          _showMessage(
                            isPaid
                                ? 'Pembayaran $startNum dibatalkan menjadi PENDING'
                                : 'Pembayaran $startNum BERHASIL diverifikasi LUNAS (PAID)',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaid ? Colors.orange.shade700 : Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: Icon(isPaid ? Icons.undo : Icons.check_circle_outline, size: 16),
                        label: Text(
                          isPaid ? 'Batal / Pending' : 'Verifikasi Lunas',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk Memuat Identitas Pemilik
  Widget _buildOwnerInfoSection(String userId, String startNum) {
    Future<Map<String, dynamic>?> fetchOwner() async {
      if (userId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) return doc.data();
      }
      // Fallback: Cari di users berdasarkan nomor start
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('startNumber', isEqualTo: startNum)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.data();
      return null;
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchOwner(),
      builder: (context, snapshot) {
        String ownerName = 'Memuat pemilik...';
        String phone = '-';

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            ownerName = snapshot.data!['fullName'] ?? 'Pembalap $startNum';
            phone = snapshot.data!['phoneNumber'] ?? snapshot.data!['email'] ?? '-';
          } else {
            ownerName = 'Pembalap $startNum';
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryMaroon,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PEMILIK / PENDAFTAR',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    Text(
                      ownerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              if (phone != '-')
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk Memuat Identitas Event & Kelas Balap
  Widget _buildEventAndClassSection(String eventId, String classId) {
    Future<Map<String, String>> fetchEventAndClass() async {
      String eventTitle = 'Kejuaraan Drag Bike';
      String eventLocation = 'Sentul';
      String className = 'Kelas Terbuka';

      if (eventId.isNotEmpty) {
        final evDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
        if (evDoc.exists && evDoc.data() != null) {
          final evData = evDoc.data()!;
          eventTitle = evData['title'] ?? eventTitle;
          eventLocation = '${evData['location'] ?? 'Sirkuit'} (${evData['distanceMeter'] ?? 201}M)';
        }

        // Ambil nama kelas jika classId ada atau ambil subkoleksi
        if (classId.isNotEmpty) {
          final clsDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('classes')
              .doc(classId)
              .get();
          if (clsDoc.exists && clsDoc.data() != null) {
            className = clsDoc.data()!['className'] ?? className;
          }
        } else {
          // Ambil kelas pertama di subcollection sebagai perwakilan
          final clsQuery = await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('classes')
              .limit(1)
              .get();
          if (clsQuery.docs.isNotEmpty) {
            className = clsQuery.docs.first.data()['className'] ?? className;
          }
        }
      }

      return {
        'title': eventTitle,
        'location': eventLocation,
        'className': className,
      };
    }

    return FutureBuilder<Map<String, String>>(
      future: fetchEventAndClass(),
      builder: (context, snapshot) {
        final title = snapshot.data?['title'] ?? 'Memuat Event...';
        final loc = snapshot.data?['location'] ?? 'Sirkuit';
        final cls = snapshot.data?['className'] ?? 'Kelas Drag';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryMaroon, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$cls • $loc',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 3. TAB 2: INPUT TELEMETRI & HASIL BALAP (Koleksi `race_results`)
  // ===========================================================================

  Widget _buildInputTelemetriTabView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.speed,
          'INPUT WAKTU TELEMETRI RESMI',
          'PENCATATAN HASIL',
        ),
        const SizedBox(height: 14),

        // Kartu Form Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilih Event
              const Text('EVENT BALAPAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(color: AppColors.primaryMaroon);
                  }
                  final events = snapshot.data!.docs;
                  if (events.isEmpty) {
                    return const Text('Tidak ada event aktif', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
                  }

                  _selectedEventId ??= events.first.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedEventId,
                        items: events.map((e) {
                          final eventData = e.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(
                              '${eventData['title'] ?? 'Kejuaraan'} (${eventData['status'] ?? ''})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedEventId = val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Nomor Start & Jalur (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NOMOR START', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _startNumberController,
                          hintText: '#402',
                          prefixIcon: Icons.tag,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('JALUR (LANE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.segmentBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedLane,
                              items: const [
                                DropdownMenuItem(value: 'LANE 01', child: Text('LANE 01', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'LANE 02', child: Text('LANE 02', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) => setState(() => _selectedLane = val ?? 'LANE 01'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Babak (Stage)
              const Text('BABAK (STAGE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedStage,
                    items: const [
                      DropdownMenuItem(value: 'QUALIFYING', child: Text('QUALIFYING (Penyisihan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'FINAL', child: Text('FINAL (Babak Utama)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) => setState(() => _selectedStage = val ?? 'QUALIFYING'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Reaction Time & Elapsed Time (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REACTION TIME (s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _reactionTimeController,
                          hintText: '0.038',
                          prefixIcon: Icons.bolt,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ELAPSED TIME (s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _elapsedTimeController,
                          hintText: '07.189',
                          prefixIcon: Icons.timer,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSavingTime ? null : _saveRaceResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSavingTime
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, color: Colors.white, size: 18),
                  label: Text(
                    _isSavingTime ? 'MENYIMPAN TELEMETRI...' : 'SIMPAN KE LEADERBOARD',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Riwayat Catatan Balap Terkini
        _buildSectionHeader(
          Icons.history,
          'CATATAN WAKTU TERBARU',
          'REALTIME TELEMETRI',
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('race_results')
              .orderBy('recordedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primaryMaroon)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCard('Belum ada catatan waktu yang diinput.');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildResultHistoryItem(data, doc.id);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _saveRaceResult() async {
    final startNum = _startNumberController.text.trim();
    final rtText = _reactionTimeController.text.trim();
    final etText = _elapsedTimeController.text.trim();

    if (startNum.isEmpty || rtText.isEmpty || etText.isEmpty) {
      _showMessage('Harap isi Nomor Start, Reaction Time, dan Elapsed Time.', isError: true);
      return;
    }

    final double? rt = double.tryParse(rtText);
    final double? et = double.tryParse(etText);

    if (rt == null || et == null) {
      _showMessage('Format angka RT atau ET tidak valid.', isError: true);
      return;
    }

    setState(() => _isSavingTime = true);

    try {
      final double totalTime = double.parse((rt + et).toStringAsFixed(3));
      final formattedStartNum = startNum.startsWith('#') ? startNum : '#$startNum';

      await FirebaseFirestore.instance.collection('race_results').add({
        'eventId': _selectedEventId ?? '',
        'startNumber': formattedStartNum,
        'lane': _selectedLane,
        'stage': _selectedStage,
        'reactionTime': rt,
        'elapsedTime': et,
        'totalTime': totalTime,
        'userId': '',
        'registrationId': '',
        'classId': '',
        'recordedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Hasil balap $formattedStartNum ($totalTime s) berhasil dicatat!');
      _startNumberController.clear();
      _reactionTimeController.clear();
      _elapsedTimeController.clear();
    } catch (e) {
      _showMessage('Gagal menyimpan hasil balap: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingTime = false);
    }
  }

  Widget _buildResultHistoryItem(Map<String, dynamic> data, String docId) {
    final startNum = data['startNumber'] ?? '#---';
    final lane = data['lane'] ?? 'LANE';
    final stage = data['stage'] ?? 'RACE';
    final total = data['totalTime'] != null ? '${data['totalTime']}s' : '-';
    final rt = data['reactionTime'] != null ? '${data['reactionTime']}s' : '-';
    final et = data['elapsedTime'] != null ? '${data['elapsedTime']}s' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  startNum,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$lane • $stage',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    'RT: $rt | ET: $et',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                total,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryMaroon,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('race_results').doc(docId).delete();
                  _showMessage('Catatan waktu dihapus.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TAB 3: KONTROL STATUS EVENT (Koleksi `events`)
  // ===========================================================================

  Widget _buildKontrolEventTabView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.flag,
          'MANAJEMEN & STATUS KEJUARAAN',
          'KONTROL LINTASAN',
        ),
        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.primaryMaroon)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCard('Belum ada event yang terdaftar.');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildEventControlCard(data, doc.id);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEventControlCard(Map<String, dynamic> data, String eventId) {
    final title = data['title'] ?? 'Kejuaraan Drag Bike';
    final location = data['location'] ?? 'Sirkuit';
    final status = data['status'] ?? 'UPCOMING';
    final distance = data['distanceMeter'] ?? 201;
    final quotaFilled = data['quotaFilled'] ?? 0;
    final quotaTotal = data['quotaTotal'] ?? 0;
    final isStageReady = status == 'STAGE_READY';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStageReady ? Colors.red.shade400 : AppColors.borderLight,
          width: isStageReady ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStageReady ? Colors.red.shade700 : AppColors.primaryMaroon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$location • $distance METER • Kuota: $quotaFilled/$quotaTotal',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          const Text('UBAH STATUS BALAP:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isStageReady
                      ? null
                      : () async {
                          await FirebaseFirestore.instance.collection('events').doc(eventId).update({'status': 'STAGE_READY'});
                          _showMessage('Event diubah menjadi STAGE_READY (Live Race)');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('LIVE (STAGE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status == 'UPCOMING'
                      ? null
                      : () async {
                          await FirebaseFirestore.instance.collection('events').doc(eventId).update({'status': 'UPCOMING'});
                          _showMessage('Event dikembalikan ke status UPCOMING');
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('UPCOMING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPER UMUM
  // ===========================================================================

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryMaroon, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5),
            ),
          ],
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM NAVIGATION BAR PANITIA
  // ===========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.receipt_long_outlined, 'Pembayaran'),
          _buildBottomNavItem(1, Icons.speed, 'Telemetri'),
          _buildBottomNavItem(2, Icons.flag_outlined, 'Event'),
          _buildBottomNavItem(3, Icons.leaderboard_outlined, 'Klasemen'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = (_bottomNavIndex == 3 && index == 3) ||
        (_bottomNavIndex != 3 && _selectedTabIndex == index && index != 3);

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          setState(() => _bottomNavIndex = 3);
        } else {
          setState(() {
            _bottomNavIndex = 0;
            _selectedTabIndex = index;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primaryMaroon,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}
