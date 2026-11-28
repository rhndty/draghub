import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../panitia/tab_telemetri_view.dart';

/// Portal Telemetri untuk Ketua dan Wakil Ketua.
///
/// Hak akses sebenarnya tetap dikontrol oleh Firebase Auth dan Firestore
/// Rules. Layar ini menjadi portal admin untuk fitur pencatatan waktu balap.
class AdminTelementryScreen extends StatelessWidget {
  const AdminTelementryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: const TabTelemetriView(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textDark,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timing Admin',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'OFFICIAL TELEMETRY',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryMaroon.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppColors.primaryMaroon,
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                'OFFICIAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryMaroon,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

/// Alias dengan penamaan yang lebih benar secara ejaan.
/// Tetap dipertahankan agar pemanggilan layar bisa lebih mudah dibaca.
class AdminTelemetryScreen extends AdminTelementryScreen {
  const AdminTelemetryScreen({super.key});
}
