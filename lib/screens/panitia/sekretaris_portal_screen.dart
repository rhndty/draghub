import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'tab_event_view.dart';
import 'tab_kehadiran_view.dart';
import 'tab_scrut_view.dart';

/// Portal Kerja Sekretaris (Alfa)
/// Menggabungkan 3 Tab Utama Tanggung Jawab Alfa:
/// 1. Draft Event & Regulasi
/// 2. Verifikasi Kehadiran & QR
/// 3. Meja Inspeksi Fisik (Scrutineering Piston)
class SekretarisPortalScreen extends StatefulWidget {
  const SekretarisPortalScreen({super.key});

  @override
  State<SekretarisPortalScreen> createState() => _SekretarisPortalScreenState();
}

class _SekretarisPortalScreenState extends State<SekretarisPortalScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TabEventView(),
    TabKehadiranView(),
    TabScrutView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: AppColors.primaryMaroon,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            activeIcon: Icon(Icons.event_note, color: AppColors.primaryMaroon),
            label: 'Event Draft',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code_scanner, color: AppColors.primaryMaroon),
            label: 'Kehadiran QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten),
            activeIcon: Icon(Icons.straighten, color: AppColors.primaryMaroon),
            label: 'Meja Scrut',
          ),
        ],
      ),
    );
  }
}

