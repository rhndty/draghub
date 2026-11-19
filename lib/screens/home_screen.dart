import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart';

// Import Modular Rider Views Sesuai PRD v1.4, ERD v1.4 & Pembagian Tugas
import 'rider/rider_upcoming_view.dart';
import 'rider/rider_ongoing_view.dart';
import 'rider/rider_podium_view.dart';

// Import Layar Pengurus (Admin / Panitia)
import 'admin/admin_event_screen.dart';
import 'admin/admin_financial_screen.dart';
import 'admin/admin_timing_screen.dart';
import 'panitia/tab_persetujuan_view.dart';
import 'panitia/sekretaris_portal_screen.dart';

/// Shell Utama Rider & Portal Komunitas DragHub (Milik Raihan / Pembalap)
/// Sesuai PRD v1.4, ERD v1.4, & Dokumen Pembagian Tugas GitFlow v1.4:
/// - Top Navbar (Segmented Bar) HANYA berisi 2 Tab:
///   * Tab 0: UPCOMING (Kejuaraan mendatang/pendaftaran buka via EventCard Alfa)
///   * Tab 1: ONGOING (Paddock live, kartu balap rider, nomor resmi #001 & QR kehadiran)
/// - Garasi Motor Balap dikelola khusus di PROFIL (ProfileScreen), TIDAK ada logic ganda di Home.
/// - Bottom Navigation Bar:
///   * Index 0: BALAPAN (Menampilkan Shell dengan Tab UPCOMING & ONGOING)
///   * Index 1: PODIUM (Menampilkan Podium resmi juara 1-3 saat COMPLETED)
///   * Index 2: PROFIL (Profil akun & Garasi Motor Balap)
/// - Floating Button: PORTAL PENGURUS (Khusus role panitia/admin)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Top Navbar: 0 = UPCOMING, 1 = ONGOING
  int _selectedTopTabIndex = 0;

  // Bottom Navbar: 0 = BALAPAN, 1 = PODIUM, 2 = PROFIL
  int _bottomNavIndex = 0;

  String _userRole = 'anggota';
  String _userName = 'Pembalap';
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  bool get _isAdmin => [
        'SUPER_ADMIN',
        'RACE_DIRECTOR',
        'VERIFIKATOR',
        'RACE_CONTROL',
        'ketua',
        'wakil',
        'sekretaris',
        'bendahara',
      ].contains(_userRole);

  @override
  void initState() {
    super.initState();
    _listenToUserRole();
  }

  void _listenToUserRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _userRole = data?['role'] ?? 'anggota';
            _userName = data?['fullName'] ??
                FirebaseAuth.instance.currentUser?.displayName ??
                'Pembalap';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildCurrentBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _isAdmin ? _buildAdminFloatingButton() : null,
    );
  }

  Widget _buildCurrentBody() {
    switch (_bottomNavIndex) {
      case 1:
        return _buildPodiumShell();
      case 2:
        return const ProfileScreen();
      case 0:
      default:
        return _buildRiderRaceShell();
    }
  }

  // ===========================================================================
  // SHELL BALAPAN: TOP BAR (UPCOMING & ONGOING)
  // ===========================================================================

  Widget _buildRiderRaceShell() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
            child: Column(
              children: [
                _buildTopHeader(),
                const SizedBox(height: 14),
                _buildRiderStatusBadge(),
                const SizedBox(height: 14),
                _buildSegmentedTabSelector(),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildActiveTopTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTopTabContent() {
    if (_selectedTopTabIndex == 0) {
      return RiderUpcomingView(
        onSwitchToOngoing: () {
          setState(() => _selectedTopTabIndex = 1);
        },
      );
    } else {
      return RiderOngoingView(
        onOpenPodium: () {
          setState(() => _bottomNavIndex = 1);
        },
      );
    }
  }

  // ===========================================================================
  // SHELL PODIUM RESMI
  // ===========================================================================

  Widget _buildPodiumShell() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
            child: Column(
              children: [
                _buildTopHeader(),
                const SizedBox(height: 14),
                _buildRiderStatusBadge(),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: RiderPodiumView(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER & STATUS BADGE
  // ===========================================================================

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.speed, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAGHUB',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'SISTEM BALAP MOTOR RESMI',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryMaroon,
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'R',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.two_wheeler, color: AppColors.primaryMaroon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _userName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryMaroon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _userRole.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryMaroon,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'PADDOCK',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP SEGMENTED BAR: HANYA UPCOMING & ONGOING (SESUAI PERMINTAAN)
  // ===========================================================================

  Widget _buildSegmentedTabSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(0, 'UPCOMING')),
          Expanded(child: _buildSegmentButton(1, 'ONGOING')),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String title) {
    final isSelected = _selectedTopTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTopTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index == 1) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.shade700 : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.6,
                  color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR: BALAPAN, PODIUM, PROFIL
  // ===========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            index: 0,
            icon: Icons.speed,
            label: 'BALAPAN',
            onTap: () {
              setState(() => _bottomNavIndex = 0);
            },
          ),
          _buildBottomNavItem(
            index: 1,
            icon: Icons.emoji_events_outlined,
            label: 'PODIUM',
            onTap: () {
              setState(() => _bottomNavIndex = 1);
            },
          ),
          _buildBottomNavItem(
            index: 2,
            icon: Icons.person_outline,
            label: 'PROFIL',
            onTap: () {
              setState(() => _bottomNavIndex = 2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _bottomNavIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? AppColors.primaryMaroon : AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FLOATING BUTTON & MODAL UNTUK ROLE PENGURUS KOMUNITAS
  // ===========================================================================

  Widget _buildAdminFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _showAdminFloatingMenu,
      backgroundColor: AppColors.primaryMaroon,
      elevation: 4,
      icon: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
      label: const Text(
        'PORTAL PENGURUS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAdminFloatingMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'PORTAL RESMI PENGURUS KOMUNITAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAdminMenuIcon(
                    icon: Icons.view_sidebar_outlined,
                    label: 'EVENT',
                    isActive: _userRole == 'SUPER_ADMIN' ||
                        _userRole == 'RACE_DIRECTOR' ||
                        _userRole == 'ketua' ||
                        _userRole == 'wakil' ||
                        _userRole == 'sekretaris',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminEventScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminMenuIcon(
                    icon: Icons.gavel_outlined,
                    label: 'PERSETUJUAN',
                    isActive: _userRole == 'SUPER_ADMIN' ||
                        _userRole == 'ketua' ||
                        _userRole == 'wakil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TabPersetujuanView(),
                        ),
                      );
                    },
                  ),
                  _buildAdminMenuIcon(
                    icon: Icons.request_quote_outlined,
                    label: 'FINANSIAL',
                    isActive: _userRole == 'SUPER_ADMIN' ||
                        _userRole == 'VERIFIKATOR' ||
                        _userRole == 'bendahara' ||
                        _userRole == 'ketua',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminFinancialScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminMenuIcon(
                    icon: Icons.timer_outlined,
                    label: 'TIMING',
                    isActive: _userRole == 'SUPER_ADMIN' ||
                        _userRole == 'RACE_CONTROL' ||
                        _userRole == 'wakil' ||
                        _userRole == 'ketua',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminTimingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminMenuIcon(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'SEKRETARIS',
                    isActive: _userRole == 'SUPER_ADMIN' ||
                        _userRole == 'sekretaris' ||
                        _userRole == 'ketua' ||
                        _userRole == 'wakil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SekretarisPortalScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminMenuIcon({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final Color color =
        isActive ? AppColors.primaryMaroon : AppColors.textMuted.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
