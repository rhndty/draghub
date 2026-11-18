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
        child: StreamBuilder<DocumentSnapshot>(
          stream: currentUserId != null
              ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
              : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
            }

            final userData = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(),
                  const SizedBox(height: 20),
                  _buildProfileCard(userData),
                  const SizedBox(height: 24),
                  _buildSectionTitleWithIcon(Icons.two_wheeler, 'GARASI MOTOR BALAP', 'SCRUTINEERING READY'),
                  const SizedBox(height: 12),
                  _buildGarageList(), // Terhubung ke root collection motorcycles
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

  Widget _buildProfileCard(Map<String, dynamic> userData) {
    String name = userData['fullName'] ?? 'Pembalap';
    String role = (userData['role'] ?? 'anggota').toUpperCase();
    String phone = userData['phoneNumber'] ?? '-';
    
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
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(userData['email'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFDF2F2), borderRadius: BorderRadius.circular(4)),
                      child: Text('ROLE: $role', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
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
            ],
          )
        ],
      ),
    );
  }

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

  Widget _buildGarageList() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: currentUserId != null
              ? FirebaseFirestore.instance.collection('motorcycles').where('userId', isEqualTo: currentUserId).snapshots()
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
                child: const Text('Garasi kosong. Daftarkan spek motor agar bisa mengikuti balapan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildGarageCard(
                    brand: data['brand'] ?? 'Merk',
                    model: data['modelName'] ?? 'Model',
                    vehicleType: data['vehicleType'] ?? 'MATIC',
                    piston: data['pistonDiameterMm']?.toString() ?? '0',
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

  Widget _buildGarageCard({required String brand, required String model, required String vehicleType, required String piston}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(brand.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(4)),
                child: Text(vehicleType, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(model, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF4F7F9), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.straighten, size: 14, color: Color(0xFF004D40)),
                const SizedBox(width: 8),
                Text('Piston Diameter: $piston mm', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('DRAGHUB SYSTEM V1.3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}