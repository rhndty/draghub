import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: AKTIF, 1: MENDATANG
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 20),
              _buildRiderStatusBadge(),
              const SizedBox(height: 16),
              _buildTabSelector(),
              const SizedBox(height: 24),
              _buildLiveEventCard(),
              const SizedBox(height: 32),
              _buildSectionTitle('KATEGORI MESIN', '3 KELAS RESMI'),
              const SizedBox(height: 12),
              _buildMachineCategories(),
              const SizedBox(height: 32),
              _buildSectionTitle('AGENDA KEJUARAAN', 'SEMUA KALENDER', showArrow: true),
              const SizedBox(height: 12),
              _buildAgendaList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- KOMPONEN HEADER ---
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Placeholder Logo
            const Icon(Icons.speed, color: AppColors.textDark, size: 24), 
            const SizedBox(width: 8),
            const Text(
              'Home',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
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

  // --- STATUS PEMBALAP ---
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
            style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: AppColors.primaryMaroon, size: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'RIDER CLASS A',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text(
            'PADDOCK LIVE',
            style: TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_outlined, size: 16, color: AppColors.textDark),
          )
        ],
      ),
    );
  }

  // --- KONTROL TAB ---
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
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
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

  // --- KARTU EVENT UTAMA ---
  Widget _buildLiveEventCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
        children: [
          // Gambar Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop', // Ganti aset lokal
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Overlay
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.primaryMaroon.withOpacity(0.9)],
                  ),
                ),
              ),
              // Tags Kiri Kanan
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: const [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('STAGE READY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                  child: const Text('LANE 01', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
              // Judul Event
              const Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  'Sentul Drag Fest 2025',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          // Info Statistik
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEventStat(Icons.flag_outlined, '201M', 'JARAK'),
                _buildEventStat(Icons.location_on_outlined, 'Sentul', 'LOKASI'),
                _buildEventStat(Icons.timer_outlined, '02:11:37', 'START'),
                _buildEventStat(Icons.people_outline, '18/20', 'KUOTA'),
              ],
            ),
          ),
          // Tombol Aksi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.sensors, size: 18, color: Colors.white),
                label: const Text('PANTAU LIVE TIMING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryMaroon, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textBadge, letterSpacing: 1.0)),
      ],
    );
  }

  // --- TITLE SECTION GENERIC ---
  Widget _buildSectionTitle(String title, String subtitle, {bool showArrow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textBadge, letterSpacing: 1.0)),
        Row(
          children: [
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: showArrow ? AppColors.primaryMaroon : AppColors.textBadge, letterSpacing: 1.0)),
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.primaryMaroon),
            ]
          ],
        )
      ],
    );
  }

  // --- KATEGORI MESIN LIST ---
  Widget _buildMachineCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryCard('Bebek 4T', 'TU 200cc', Icons.motorcycle_outlined),
          const SizedBox(width: 12),
          _buildCategoryCard('Sport 2T', 'Frame STD', Icons.electric_bolt_outlined),
          const SizedBox(width: 12),
          _buildCategoryCard('Matic', '200cc', Icons.speed_outlined),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryMaroon, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          )
        ],
      ),
    );
  }

  // --- AGENDA LIST ---
  Widget _buildAgendaList() {
    return Column(
      children: [
        _buildAgendaItem('402\nMETER', 'Gadhuro Drag Series', 'Meikarta', 'Rp 85Jt', isPrice: true),
        const SizedBox(height: 12),
        _buildAgendaItem('201\nMETER', 'IDW Round 3', 'Wonosari', '08 Jun', isPrice: false),
      ],
    );
  }

  Widget _buildAgendaItem(String distance, String title, String location, String detail, {required bool isPrice}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: Text(
              distance,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primaryMaroon),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 12),
                    Icon(isPrice ? Icons.payments_outlined : Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(detail, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.segmentBackground, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          )
        ],
      ),
    );
  }

  // --- BOTTOM NAVIGATION BAR KUSTOM ---
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
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
      onTap: () => setState(() => _bottomNavIndex = index),
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