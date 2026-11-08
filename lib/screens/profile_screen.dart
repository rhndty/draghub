import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'add_bike_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // StreamBuilder UTAMA untuk memuat data Profil & Telemetri
        child: StreamBuilder<DocumentSnapshot>(
          stream: currentUserId != null
              ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
              : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
            }

            // Ambil data user, jika kosong siapkan map kosong agar tidak error
            final userData = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(),
                  const SizedBox(height: 20),
                  _buildProfileCard(userData), // Kirim data ke Kartu Profil
                  const SizedBox(height: 24),
                  _buildSectionTitleWithIcon(Icons.timeline, 'TELEMETRI UTAMA', '201M SENSOR DRAFT'),
                  const SizedBox(height: 12),
                  _buildTelemetryGrid(userData), // Kirim data ke Grid Telemetri
                  const SizedBox(height: 24),
                  _buildSectionTitleWithIcon(Icons.two_wheeler, 'GARASI MOTOR BALAP', 'SCRUTINEERING READY'),
                  const SizedBox(height: 12),
                  _buildGarageList(), // Punya StreamBuilder sendiri untuk subcollection
                  const SizedBox(height: 24),
                  _buildSectionTitleWithIcon(Icons.folder_shared_outlined, 'DOKUMEN & PADDOCK PASS', ''),
                  const SizedBox(height: 12),
                  _buildMenuOptions(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. HEADER ATAS ---
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.speed, color: AppColors.textDark, size: 24),
            SizedBox(width: 8),
            Text('Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 0.5)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  // --- 2. KARTU PROFIL DINAMIS ---
  Widget _buildProfileCard(Map<String, dynamic> userData) {
    // Menyiapkan nilai fallback jika data di Firestore belum diisi
    String name = userData['fullName'] ?? 'Pembalap';
    String teamName = userData['teamName']?.toString().isNotEmpty == true ? userData['teamName'] : 'Belum Bergabung Tim';
    String startNumber = userData['startNumber']?.toString().isNotEmpty == true ? userData['startNumber'] : '#--';
    String riderClass = userData['riderClass'] ?? 'NOVICE';
    String imiLicense = userData['imiLicense']?.toString().isNotEmpty == true ? userData['imiLicense'] : 'Belum Terdaftar';
    String photoUrl = userData['photoUrl'] ?? 'https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}&background=800000&color=fff';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.person, size: 36, color: AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.primaryMaroon, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(teamName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(4)),
                          child: Text(riderClass.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('GATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                  Text(startNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF4F7F9), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF004D40)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Lisensi IMI: $imiLicense', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF004D40), shape: BoxShape.circle)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.segmentBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit, size: 14, color: AppColors.textDark),
                  label: const Text('EDIT PROFIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.share, size: 14, color: Colors.white),
                  label: const Text('BAGIKAN RIDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- 3. JUDUL SEKSI & GRID TELEMETRI DINAMIS ---
  Widget _buildSectionTitleWithIcon(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryMaroon),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textBadge, letterSpacing: 1.0)),
          ],
        ),
        if (subtitle.isNotEmpty)
          Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textBadge, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildTelemetryGrid(Map<String, dynamic> userData) {
    // Menarik data metrik dari Firestore, fallback ke 0 jika belum ada
    String bestRt = userData['bestReactionTime']?.toString() ?? '0.000';
    String bestTime = userData['personalBest201m']?.toString() ?? '00.000';
    String topSpeed = userData['topSpeedKmH']?.toString() ?? '0.0';
    String starts = userData['totalStarts']?.toString() ?? '0';
    String podiums = userData['totalPodiums']?.toString() ?? '0';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildTelemetryCard('BEST REACTION', bestRt, 's', 'Perfect Tree Index', Icons.bolt, true),
        _buildTelemetryCard('PERSONAL BEST 201M', bestTime, 's', 'FFA Record Holder', Icons.emoji_events_outlined, true),
        _buildTelemetryCard('SPEED TRAP (FINISH)', topSpeed, 'km/h', 'DragHub Wind-Tunnel Spec', Icons.speed, false),
        _buildTelemetryCard('STARTS / PODIUM', '$starts / $podiums', '', 'Total Partisipasi', Icons.insights, false),
      ],
    );
  }

  Widget _buildTelemetryCard(String title, String value, String unit, String subtitle, IconData icon, bool highlightSubtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8)),
              Icon(icon, size: 14, color: AppColors.primaryMaroon),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 10, color: highlightSubtitle ? AppColors.primaryMaroon : AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: highlightSubtitle ? AppColors.primaryMaroon : AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. DAFTAR GARASI MOTOR DINAMIS (DARI SUBCOLLECTION) ---
  Widget _buildGarageList() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: currentUserId != null
              ? FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('garage').snapshots()
              : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.primaryMaroon),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                child: const Text('Garasi kosong. Belum ada motor yang didaftarkan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }

            // Looping data motor dari subcollection garage
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final bikeData = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildGarageCard(
                    className: bikeData['targetClass'] ?? 'Kelas Bebas',
                    bikeName: bikeData['modelBasis'] ?? 'Motor Balap',
                    status: bikeData['status'] ?? 'MENUNGGU VERIFIKASI',
                    transponder: bikeData['transponder']?.toString().isNotEmpty == true ? bikeData['transponder'] : 'Belum Ada',
                    weight: '${bikeData['weightKg'] ?? 0} KG',
                    note: bikeData['tunerNotes']?.toString().isNotEmpty == true ? bikeData['tunerNotes'] : 'Tidak ada catatan',
                    isVerified: bikeData['status'] == 'TERVERIFIKASI', // Status akan merubah warna/ikon
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBikeScreen())),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderLight, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryMaroon),
            label: const Text('TAMBAH MOTOR BALAP BARU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.primaryMaroon)),
          ),
        )
      ],
    );
  }

  Widget _buildGarageCard({
    required String className,
    required String bikeName,
    required String status,
    required String transponder,
    required String weight,
    required String note,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('KELAS: ${className.toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFE8F5E9) : AppColors.segmentBackground, 
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text(
                  status, 
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isVerified ? Colors.green.shade800 : AppColors.textDark, letterSpacing: 0.5)
                ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(bikeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildBikeSpec('TRANSPONDER', transponder)),
                Container(width: 1, height: 24, color: AppColors.borderLight),
                const SizedBox(width: 12),
                Expanded(child: _buildBikeSpec('BOBOT SCRUT', weight)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(isVerified ? Icons.check_circle_outline : Icons.tune, size: 14, color: isVerified ? Colors.green : AppColors.textDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Text('DETAIL SETUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.5)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryMaroon),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBikeSpec(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // --- 5. MENU DOKUMEN & PENGATURAN ---
  Widget _buildMenuOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildMenuTile(Icons.qr_code_2, 'E-Paddock Pass & Barcode Gate', 'Akses Jalur Pit, Grid Walk & Scrutineering'),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildMenuTile(Icons.health_and_safety_outlined, 'Asuransi Balap & Rekam Medis', 'Gold Card BPJS & IMI Racing Coverage Aktif'),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildMenuTile(Icons.tune, 'Preferensi Sensor & Akun', 'Pengaturan Notifikasi Event & Transponder Sync'),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primaryMaroon, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () {},
    );
  }

  // --- 6. FOOTER BAWAH ---
  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('DRAGHUB DRAG CHRONO SYSTEM V1.0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Official Scrutineered Profile • Live Synced', style: TextStyle(fontSize: 9, color: AppColors.textMuted.withOpacity(0.7))),
        ],
      ),
    );
  }
}