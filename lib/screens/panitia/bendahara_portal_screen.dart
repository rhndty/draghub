import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'tab_pembayaran_view.dart';
import 'tab_kas_view.dart';

/// Portal Kerja Bendahara (Dika)
/// Menggabungkan 2 Tab Utama Tanggung Jawab Dika:
/// 1. Verifikasi Pembayaran & Penomoran Balap Urut Lunas (serta opsi Midtrans Sandbox)
/// 2. Buku Kas & Riwayat Transaksi Komunitas (Proteksi Khusus Panitia)
class BendaharaPortalScreen extends StatefulWidget {
  const BendaharaPortalScreen({super.key});

  @override
  State<BendaharaPortalScreen> createState() => _BendaharaPortalScreenState();
}

class _BendaharaPortalScreenState extends State<BendaharaPortalScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TabPembayaranView(),
    TabKasView(),
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
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user, color: AppColors.primaryMaroon),
            label: 'Verifikasi Bayar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet, color: AppColors.primaryMaroon),
            label: 'Buku Kas',
          ),
        ],
      ),
    );
  }
}
