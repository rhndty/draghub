import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'leaderboard_screen.dart';

// import 'leaderboard_screen.dart'; // Aktifkan jika layar leaderboard sudah dipasang ke navigasi bawah

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex =
      1; // Default ke 1 untuk menampilkan tab MENDATANG sesuai permintaan
  int _bottomNavIndex = 0;
  int _selectedMonthFilterIndex = 0; // Filter bulan untuk tab Mendatang

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _bottomNavIndex == 1
          ? const LeaderboardScreen()
          : SafeArea(
              child: Column(
                children: [
                  // Bagian Header Tetap (Tidak ikut terscroll agar selalu terlihat)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
                    child: Column(
                      children: [
                        _buildTopHeader(),
                        const SizedBox(height: 20),
                        _buildRiderStatusBadge(),
                        const SizedBox(height: 16),
                        _buildTabSelector(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Bagian Konten Dinamis yang bisa di-scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _selectedTabIndex == 0
                          ? _buildActiveView()
                          : _buildUpcomingView(),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ===========================================================================
  // WIDGET HEADER & NAVIGASI UMUM
  // ===========================================================================

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.speed,
              color: AppColors.textDark,
              size: 24,
            ), // Logo
            const SizedBox(width: 8),
            Text(
              _selectedTabIndex == 0 ? 'Home' : 'DragHub Mendatang',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryMaroon,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildRiderStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '#402',
            style: TextStyle(
              color: AppColors.primaryMaroon,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: AppColors.primaryMaroon, size: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'RIDER CLASS A',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'PADDOCK LIVE',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, 'AKTIF (1)')),
          Expanded(child: _buildTabButton(1, 'MENDATANG (2)')),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 1.0,
              color: isSelected ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN TAB 2: MENDATANG (UPCOMING EVENTS)
  // ===========================================================================

  Widget _buildUpcomingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthFilters(),
        const SizedBox(height: 20),
        _buildPriorityBanner(),
        const SizedBox(height: 24),
        _buildUpcomingSectionTitle('CHAMPIONSHIP UTAMA', 'SERI 02 / 2026'),
        const SizedBox(height: 16),

        // MENGAMBIL DATA DARI FIRESTORE SECARA REAL-TIME
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where(
                'status',
                isEqualTo: 'UPCOMING',
              ) // Ambil yang statusnya UPCOMING
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Jika masih loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryMaroon,
                  ),
                ),
              );
            }

            // 2. Jika database kosong atau error
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Belum ada jadwal kejuaraan mendatang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            // 3. Jika ada data, buat list kartu berdasarkan data dari backend
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final eventId = doc.id; // Ambil ID dokumen
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildUpcomingEventCard(
                    data,
                    eventId,
                  ), // Kirim data ke Card
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMonthFilters() {
    final months = ['SEMUA', 'MEI 2025', 'JUNI 2025', 'JULI 2025'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(months.length, (index) {
          final isSelected = _selectedMonthFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedMonthFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryMaroon : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryMaroon
                      : AppColors.borderLight,
                ),
              ),
              child: Text(
                months[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPriorityBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2), // Merah muda sangat terang
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryMaroon.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.verified,
              color: AppColors.primaryMaroon,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SLOT PRIORITAS TERBUKA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryMaroon,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '#402',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMaroon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'Notifikasi siap untuk kelas '),
                      TextSpan(
                        text: 'Bebek 4T TU 200cc',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '. Pra-registrasi resmi dimulai pekan ini.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSectionTitle(String title, String badgeText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.primaryMaroon, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryMaroon,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(Map<String, dynamic> data, String eventId) {
    // Memformat Tanggal dari Firestore Timestamp ke Teks (Misal: "18 MEI")
    String day = "--";
    String monthStr = "---";
    if (data['eventDate'] != null) {
      DateTime date = (data['eventDate'] as Timestamp).toDate();
      day = date.day.toString();
      List<String> months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MEI',
        'JUN',
        'JUL',
        'AGU',
        'SEP',
        'OKT',
        'NOV',
        'DES',
      ];
      monthStr = months[date.month - 1];
    }

    // Menghitung Sisa Slot Otomatis
    int total = data['quotaTotal'] ?? 0;
    int filled = data['quotaFilled'] ?? 0;
    int remainingSlots = total - filled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Header Event
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  data['bannerUrl'] ?? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              // Badge "SEGERA"
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.circle,
                        color: AppColors.primaryMaroon,
                        size: 8,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PENDAFTARAN BUKA',
                        style: TextStyle(
                          color: AppColors.primaryMaroon,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge Jarak Dinamis
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${data['distanceMeter'] ?? 201}M STRIP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              // Judul Dinamis
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        data['title'] ?? 'Kejuaraan Drag Bike',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bookmark_border,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Statistik Row (Tanggal dan Kuota jadi Dinamis)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildUpcomingStat(
                  Icons.calendar_month,
                  '$day $monthStr',
                  'TANGGAL',
                ),
                // Jika ingin dinamis, Anda bisa menambahkan field 'totalPrize' (string) di Firestore nanti
                _buildUpcomingStat(
                  Icons.emoji_events_outlined,
                  'Rp 85 JT',
                  'HADIAH',
                  valueColor: AppColors.primaryMaroon,
                ),
                _buildUpcomingStat(
                  Icons.group_outlined,
                  '$remainingSlots SLOT',
                  'SISA KUOTA',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // MENGAMBIL DAFTAR KELAS DARI SUBCOLLECTION FIRESTORE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'KELAS: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    // Tarik data dari Subcollection 'classes' berdasarkan eventId ini
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId)
                        .collection('classes')
                        .get(),
                    builder: (context, classSnapshot) {
                      if (!classSnapshot.hasData ||
                          classSnapshot.data!.docs.isEmpty) {
                        return const Text(
                          'Memuat kelas...',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        );
                      }
                      // Render kelas dinamis
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: classSnapshot.data!.docs.map((clsDoc) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildClassChip(
                                clsDoc['className'] ?? 'Kelas Bebas',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tombol Regulasi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.segmentBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.menu_book,
                  size: 16,
                  color: AppColors.textDark,
                ),
                label: const Text(
                  'REGULASI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingStat(
    IconData icon,
    String value,
    String label, {
    Color valueColor = AppColors.textDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryMaroon, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildClassChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // ===========================================================================
  // TAMPILAN TAB 1: AKTIF / SEDANG BERLANGSUNG
  // ===========================================================================

  Widget _buildActiveView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MENGAMBIL DATA EVENT YANG SEDANG LIVE (STAGE_READY) DARI FIRESTORE
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where(
                'status',
                isEqualTo: 'STAGE_READY',
              ) // Filter event yang sedang berjalan
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryMaroon,
                  ),
                ),
              );
            }

            // 2. Jika tidak ada event yang aktif hari ini
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.sports_score,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Paddock Sedang Kosong',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ada kejuaraan yang berlangsung hari ini. Cek tab Mendatang untuk jadwal berikutnya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Render event aktif pertama yang ditemukan
            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLiveEventCard(data), // Membangun kartu event live
                const SizedBox(height: 24),
                _buildAgendaSection(), // Membangun agenda hari ini
              ],
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // KARTU EVENT AKTIF
  Widget _buildLiveEventCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMaroon.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Header Event Aktif
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  data['bannerUrl'] ?? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
              // Badge LIVE Merah Kiri Atas
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.sensors, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'RACE LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Judul & Lokasi Dinamis
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Kejuaraan Drag Bike',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryMaroon,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['location'] ?? 'Sirkuit'} • ${data['distanceMeter'] ?? 201}M',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tombol Buka Live Timing (Berpindah Layar)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Ajaib! Saat diklik, ini akan mengubah navigasi ke tab ke-2 (Leaderboard)
                  setState(() => _bottomNavIndex = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.timer, size: 20, color: Colors.white),
                label: const Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET AGENDA / JADWAL HARI INI
  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.view_timeline_outlined,
              color: AppColors.primaryMaroon,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'AGENDA HARI INI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Item Agenda Statis (Bisa diubah jadi dinamis nanti jika ada koleksi 'agendas' di Firestore)
        _buildAgendaItem('08:00', 'Scrutineering & Daftar Ulang', isDone: true),
        _buildAgendaItem('10:00', 'Briefing Pembalap', isDone: true),
        _buildAgendaItem('11:00', 'Penyisihan Kelas Utama', isActive: true),
        _buildAgendaItem('14:00', 'Final Kelas Utama', isDone: false),
        _buildAgendaItem('16:30', 'Pembagian Tropi & Podium', isDone: false),
      ],
    );
  }

  Widget _buildAgendaItem(
    String time,
    String title, {
    bool isDone = false,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryMaroon
                    : (isDone ? Colors.green : AppColors.borderLight),
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: AppColors.primaryMaroon.withOpacity(0.3),
                        width: 4,
                      )
                    : null,
              ),
            ),
            Container(
              width: 2,
              height: 44,
              color: AppColors.borderLight,
            ), // Garis vertikal penghubung
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? AppColors.primaryMaroon
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                  color: isActive
                      ? AppColors.textDark
                      : (isDone ? AppColors.textMuted : AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR KUSTOM
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
          _buildBottomNavItem(0, Icons.home_outlined),
          _buildBottomNavItem(1, Icons.leaderboard_outlined),
          _buildBottomNavItem(2, Icons.sports_motorsports_outlined),
          _buildBottomNavItem(3, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _bottomNavIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
            size: 26,
          ),
          const SizedBox(height: 4),
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
