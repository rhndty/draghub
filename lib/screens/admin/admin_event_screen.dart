import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';
import '../admin/admin_create_event_screen.dart'; // Pastikan import ini ada

class AdminEventScreen extends StatefulWidget {
  const AdminEventScreen({super.key});

  @override
  State<AdminEventScreen> createState() => _AdminEventScreenState();
}

class _AdminEventScreenState extends State<AdminEventScreen> {
  final int _adminNavIndex = 0; // 0 = EVENT

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAdminAppBar(),
      // 1. STREAM BUILDER UTAMA: Menarik Event yang paling baru dibuat
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Mengekstrak data event dari Firestore
          final eventDoc = snapshot.data!.docs.first;
          final eventData = eventDoc.data() as Map<String, dynamic>;
          final eventId = eventDoc.id;

          // Membaca status dinamis dari database (fallback ke nilai default jika null)
          bool isTrackHot = eventData['isTrackHot'] ?? true;
          Map<String, dynamic> inspections = eventData['inspections'] ?? {};
          bool sensorChecked = inspections['sensor'] ?? false;
          bool medicalChecked = inspections['medical'] ?? false;
          bool scrutChecked = inspections['scrut'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleHeader(),
                const SizedBox(height: 16),
                _buildCircuitStatusWidget(eventData, eventId, isTrackHot),
                const SizedBox(height: 16),
                _buildMainActionButtons(context),
                const SizedBox(height: 24),
                _buildQuotaManagementSection(eventId), // Sub-StreamBuilder untuk Kelas
                const SizedBox(height: 24),
                _buildInspectionChecklist(eventId, sensorChecked, medicalChecked, scrutChecked),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildAdminBottomNav(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Belum ada Event yang berjalan.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEventScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('BUAT EVENT SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- KOMPONEN UI STATIS (Desain Tetap Terjaga) ---

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
            child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
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

  Widget _buildRoleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFDF2F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.1))),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('PERAN: RACE DIRECTOR & ADMIN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon, letterSpacing: 1.0)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLight)),
              child: Row(
                children: const [
                  Icon(Icons.dns_outlined, size: 10, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('SYS-RD-992', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Race Director', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF2E7D32)),
                  SizedBox(width: 4),
                  Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: Text('Otorisasi Tingkat 1 • Regulasi sirkuit, telemetri, & alokasi start', style: TextStyle(fontSize: 10, color: AppColors.textMuted))),
            Text('MASTER\nCONSOLE', textAlign: TextAlign.right, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textBadge, letterSpacing: 1.0, height: 1.2)),
          ],
        ),
      ],
    );
  }

  // --- KOMPONEN DINAMIS ---

  Widget _buildCircuitStatusWidget(Map<String, dynamic> eventData, String eventId, bool isTrackHot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isTrackHot ? AppColors.primaryMaroon : AppColors.textMuted, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.flag, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('CIRCUIT STATUS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(2)), child: Text('${eventData['distanceMeter'] ?? 201}M', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(eventData['title'] ?? 'Event Balap', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: isTrackHot ? AppColors.primaryMaroon : AppColors.textMuted, borderRadius: BorderRadius.circular(16)),
                child: Text(isTrackHot ? 'HOT TRACK' : 'RED FLAG', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight)), child: const Icon(Icons.edit, size: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          // Cuaca statis sebagai mock-up sensor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildWeatherMetric(Icons.thermostat, 'ASPAL', '32.4°C', 'Grip Optimal', const Color(0xFF2E7D32))),
                Container(width: 1, height: 30, color: AppColors.borderLight),
                Expanded(child: _buildWeatherMetric(Icons.air, 'ANGIN', '4.2 m/s', 'Headwind NW', AppColors.textMuted)),
                Container(width: 1, height: 30, color: AppColors.borderLight),
                Expanded(child: _buildWeatherMetric(Icons.water_drop_outlined, 'LEMBAB', '62%', 'Density: 1.18', AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // TOMBOL INTERAKTIF KE FIRESTORE
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FirebaseFirestore.instance.collection('events').doc(eventId).update({'isTrackHot': true}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: isTrackHot ? AppColors.primaryMaroon : AppColors.segmentBackground, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag, size: 14, color: isTrackHot ? Colors.white : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('TRACK OPEN / HOT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isTrackHot ? Colors.white : AppColors.textMuted, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => FirebaseFirestore.instance.collection('events').doc(eventId).update({'isTrackHot': false}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: !isTrackHot ? AppColors.textBadge : AppColors.segmentBackground, borderRadius: const BorderRadius.horizontal(right: Radius.circular(8))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.do_not_disturb_alt, size: 14, color: !isTrackHot ? Colors.white : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('RED FLAG / CLOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: !isTrackHot ? Colors.white : AppColors.textMuted, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String title, String value, String subtitle, Color subtitleColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: AppColors.primaryMaroon),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 8, color: subtitleColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMainActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            // Navigasi ke halaman Buat Event
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEventScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
            label: const Text('BUAT EVENT DRAG BARU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSecondaryActionButton(Icons.edit_calendar, 'EDIT EVENT')),
            const SizedBox(width: 8),
            Expanded(child: _buildSecondaryActionButton(Icons.menu_book, 'REGULASI')),
            const SizedBox(width: 8),
            Expanded(child: _buildSecondaryActionButton(Icons.file_download_outlined, 'EKSPOR')),
          ],
        )
      ],
    );
  }

  Widget _buildSecondaryActionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: AppColors.borderLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      icon: Icon(icon, size: 12, color: AppColors.primaryMaroon),
      label: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5)),
    );
  }

  // --- KELAS BALAP DINAMIS DARI FIRESTORE ---
  Widget _buildQuotaManagementSection(String eventId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.people_outline, color: AppColors.primaryMaroon, size: 16),
                SizedBox(width: 8),
                Text('Manajemen Kuota Kelas Balap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // STREAM BUILDER KEDUA: Membaca Subcollection Kelas
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').doc(eventId).collection('classes').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primaryMaroon)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                child: const Text('Belum ada kelas balap yang diatur.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }

            final classes = snapshot.data!.docs;

            return Column(
              children: classes.map((doc) {
                final clsData = doc.data() as Map<String, dynamic>;
                int total = clsData['maxStarter'] ?? 30;
                int filled = clsData['registeredCount'] ?? 0;
                double percentage = (filled / total) * 100;
                int remaining = total - filled;

                // Logika Desain UI Cerdas berdasarkan Kapasitas
                String badgeText = percentage >= 100 ? 'PENUH' : (filled > 0 ? 'AKTIF' : 'BUKA');
                Color badgeColor = percentage >= 100 ? AppColors.primaryMaroon : const Color(0xFF2E7D32);
                Color badgeBgColor = percentage >= 100 ? const Color(0xFFFDF2F2) : const Color(0xFFE8F5E9);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildClassQuotaCard(
                    className: clsData['className'] ?? 'Kelas Bebas',
                    badgeText: badgeText, badgeColor: badgeColor, badgeBgColor: badgeBgColor,
                    filled: filled, total: total, percentage: percentage.toInt(),
                    subtitle: 'Harga Pendaftaran: ${clsData['price'] ?? '-'}',
                    bottomLeftText: percentage >= 100 ? 'Antrian Waiting List Dibuka' : '$remaining Slot Tersisa',
                    bottomLeftIcon: percentage >= 100 ? Icons.hourglass_empty : Icons.check_circle_outline,
                    actionButtons: [
                      if (percentage < 100) _buildSmallOutlineButton(Icons.add, '+5 SLOT', AppColors.primaryMaroon),
                      if (percentage >= 100) _buildSmallOutlineButton(Icons.list_alt, 'BUKA WAITING LIST', AppColors.primaryMaroon, bgColor: const Color(0xFFFDF2F2)),
                      const SizedBox(width: 8),
                      _buildSmallOutlineButton(Icons.lock_outline, 'KUNCI KELAS', AppColors.textMuted),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassQuotaCard({
    required String className, required String badgeText, required Color badgeColor, required Color badgeBgColor,
    required int filled, required int total, required int percentage,
    required String subtitle, required String bottomLeftText, IconData? bottomLeftIcon, required List<Widget> actionButtons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(className, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(4)), child: Text(badgeText, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: badgeColor, letterSpacing: 1.0))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$filled/$total', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('$percentage% TERISI', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: percentage >= 100 ? AppColors.primaryMaroon : AppColors.textMuted, letterSpacing: 0.5)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.segmentBackground,
              color: AppColors.primaryMaroon,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (bottomLeftIcon != null) ...[Icon(bottomLeftIcon, size: 10, color: AppColors.textMuted), const SizedBox(width: 4)],
                    Expanded(child: Text(bottomLeftText, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              Row(children: actionButtons),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallOutlineButton(IconData icon, String label, Color color, {Color bgColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: color == AppColors.textMuted ? AppColors.borderLight : color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // --- INSPEKSI TERSIMPAN KE DATABASE ---
  Widget _buildInspectionChecklist(String eventId, bool sensorChecked, bool medicalChecked, bool scrutChecked) {
    int checkedCount = (sensorChecked ? 1 : 0) + (medicalChecked ? 1 : 0) + (scrutChecked ? 1 : 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.fact_check_outlined, color: AppColors.primaryMaroon, size: 16),
                SizedBox(width: 8),
                Text('Inspeksi Kesiapan Sirkuit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: Text('$checkedCount/3 LOLOS', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), letterSpacing: 1.0)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildChecklistItem(
          title: 'Sensor Chrono & Tree Light',
          subtitle: 'Laser photogate 60ft, 201m, 402m terkalibrasi',
          value: sensorChecked,
          onChanged: (val) {
            FirebaseFirestore.instance.collection('events').doc(eventId).set({'inspections': {'sensor': val}}, SetOptions(merge: true));
          },
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          title: 'Tim Medis & Safety Car',
          subtitle: '2 Unit Ambulans + APAR foam 50L siaga di ujung runoff',
          value: medicalChecked,
          onChanged: (val) {
            FirebaseFirestore.instance.collection('events').doc(eventId).set({'inspections': {'medical': val}}, SetOptions(merge: true));
          },
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          title: 'Scrutineering Bay Terbuka',
          subtitle: 'Timbangan digital & buret kubikasi siap operasi',
          value: scrutChecked,
          onChanged: (val) {
            FirebaseFirestore.instance.collection('events').doc(eventId).set({'inspections': {'scrut': val}}, SetOptions(merge: true));
          },
        ),
      ],
    );
  }

  Widget _buildChecklistItem({required String title, required String subtitle, required bool value, required Function(bool?) onChanged}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: Checkbox(
              value: value,
              activeColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (value) const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
        ],
      ),
    );
  }

  Widget _buildAdminBottomNav() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, Icons.view_sidebar, 'EVENT'),
          _buildNavIcon(1, Icons.request_quote_outlined, 'FINANSIAL'),
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
        if (index == 0) return; 
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