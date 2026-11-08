import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
import 'panitia/tab_kas_view.dart';
import 'panitia/tab_telemetri_view.dart';
import 'panitia/tab_event_view.dart';

class PanitiaHomeScreen extends StatefulWidget {
  const PanitiaHomeScreen({super.key});

  @override
  State<PanitiaHomeScreen> createState() => _PanitiaHomeScreenState();
}

class _PanitiaHomeScreenState extends State<PanitiaHomeScreen> {
  int _selectedTabIndex = 0; // 0: Pembayaran/Kas, 1: Telemetri, 2: Event
  int _bottomNavIndex = 0; // 3: Leaderboard

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _bottomNavIndex == 3
          ? const LeaderboardScreen()
          : SafeArea(
              child: Column(
                children: [
                  // Header & Status Badge Panitia
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

                  // Konten Tab Aktif (Modul Terpisah)
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
  // 1. HEADER & STATUS BADGE
  // ===========================================================================

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
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
                  'Akses Penuh: Verifikasi Kas/Pembayaran, Telemetri, Kontrol Event',
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

  // ===========================================================================
  // 2. KONTEN MODULAR TAB
  // ===========================================================================

  Widget _buildCurrentTabView() {
    switch (_selectedTabIndex) {
      case 0:
        return const TabKasView(); // Modul Dika (Bendahara)
      case 1:
        return const TabTelemetriView(); // Modul Raihan (Wakil / Telemetri)
      case 2:
        return const TabEventView(); // Modul Alfa (Sekretaris / Event)
      default:
        return const TabKasView();
    }
  }

  // ===========================================================================
  // 3. BOTTOM NAVIGATION BAR
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
