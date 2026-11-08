import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

/// Tab Verifikasi Pembayaran & Kas Komunitas (Modul Milik Dika / Bendahara)
class TabKasView extends StatefulWidget {
  const TabKasView({super.key});

  @override
  State<TabKasView> createState() => _TabKasViewState();
}

class _TabKasViewState extends State<TabKasView> {
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

  void _showPaymentProofDialog(
    BuildContext context,
    String? url,
    String startNumber,
    String ownerName,
  ) {
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
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
                              const Text(
                                'Gagal memuat gambar bukti transfer.',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  url,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                                ),
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
                            const Text(
                              'Belum ada tautan gambar bukti transfer.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            if (url != null && url.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  url,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                                ),
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
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildOwnerInfoSection(userId, startNum),
                const SizedBox(height: 12),
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

  Widget _buildOwnerInfoSection(String userId, String startNum) {
    Future<Map<String, dynamic>?> fetchOwner() async {
      if (userId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) return doc.data();
      }
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
}

