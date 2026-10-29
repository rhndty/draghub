import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
              const SizedBox(height: 16),
              _buildLiveBadge(),
              const SizedBox(height: 16),
              _buildCurrentRiderCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('PODIUM STANDING', '201M SPRINT'),
              const SizedBox(height: 12),
              _buildPodiumStandingList(),
              const SizedBox(height: 24),
              _buildSectionTitleWithIcon(
                Icons.receipt_long_outlined,
                'TIME SLIP TELEMETRY',
                'LANE B',
              ),
              const SizedBox(height: 12),
              _buildTelemetryGrid(),
              const SizedBox(height: 24),
              _buildTimingWatermark(),
              const SizedBox(height: 20),
              _buildShareButton(),
              const SizedBox(height: 16),
            ],
          ),
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
            Text(
              'Leaderboard',
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

  // --- 2. BADGE LIVE HEAT ---
  Widget _buildLiveBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.segmentBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMaroon,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'HEAT 04 • FINAL 201M',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: const [
            Icon(Icons.sensors, color: AppColors.primaryMaroon, size: 16),
            SizedBox(width: 4),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. KARTU INFORMASI PEMBALAP SAAT INI ---
  Widget _buildCurrentRiderCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        String name = 'Raka #402';
        String riderClass = 'FFA 350cc';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            name =
                '${data['fullName'] ?? 'Raka'} ${data['startNumber'] ?? '#402'}';
            riderClass = data['riderClass'] ?? 'FFA 350cc';
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: AppColors.primaryMaroon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SCRUTINEERING OK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CLASS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    riderClass,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. TITLE SECTION GENERIC ---
  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textBadge,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textBadge,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitleWithIcon(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryMaroon),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textBadge,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textBadge,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // --- 5. DAFTAR KLASEMEN PODIUM (P1, P2, P3) ---
  Widget _buildPodiumStandingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('race_results')
          .orderBy('totalTime', descending: false)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        // Data default/mockup jika data di Firestore belum siap
        List<Map<String, dynamic>> standings = [
          {
            'rank': 'P1',
            'name': 'Ardiansyah #118',
            'rt': '0.042s',
            'time': '07.124s',
            'isUser': false,
            'icon': Icons.emoji_events,
            'iconColor': const Color(0xFFFFD700), // Emas
          },
          {
            'rank': 'P2',
            'name': 'Raka #402',
            'rt': '0.038s • +0.065s',
            'time': '07.189s',
            'isUser': true,
            'icon': Icons.military_tech,
            'iconColor': const Color(0xFFC0C0C0), // Perak
          },
          {
            'rank': 'P3',
            'name': 'Dimas #88',
            'rt': '0.051s',
            'time': '07.250s',
            'isUser': false,
            'icon': Icons.military_tech,
            'iconColor': const Color(0xFFCD7F32), // Perunggu
          },
        ];

        // Jika data dari Firestore tersedia, perbarui list
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          for (int i = 0; i < docs.length && i < 3; i++) {
            final data = docs[i].data() as Map<String, dynamic>;
            standings[i]['name'] = '${data['startNumber'] ?? '#402'}';
            standings[i]['time'] =
                '${(data['totalTime'] ?? 0.0).toStringAsFixed(3)}s';
            standings[i]['rt'] =
                'RT ${(data['reactionTime'] ?? 0.0).toStringAsFixed(3)}s';
            if (data['userId'] == currentUserId) {
              standings[i]['isUser'] = true;
            }
          }
        }

        return Column(
          children: standings.map((item) => _buildPodiumItem(item)).toList(),
        );
      },
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> item) {
    final bool isUser = item['isUser'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFFFDE8E8)
            : Colors.white, // Highlight merah muda jika posisi user
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUser ? AppColors.primaryMaroon : AppColors.borderLight,
          width: isUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon Medali / Trophy
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.segmentBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'] as IconData,
              color: item['iconColor'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info Nama & Rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${item['rank']} ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? AppColors.primaryMaroon
                            : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      item['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMaroon,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'RT ${item['rt']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser
                        ? AppColors.primaryMaroon.withOpacity(0.8)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Total Waktu Tempuh
          Text(
            item['time'] as String,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isUser ? AppColors.primaryMaroon : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. GRID TIME SLIP TELEMETRY (2x2) ---
  Widget _buildTelemetryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildTelemetryCard(
          'REACTION TIME',
          '0.038',
          's',
          Icons.bolt,
          isHighlight: false,
        ),
        _buildTelemetryCard(
          '60 FT LAUNCH',
          '1.612',
          's',
          Icons.rocket_launch,
          isHighlight: false,
        ),
        _buildTelemetryCard(
          'ELAPSED TIME',
          '07.189',
          's',
          Icons.timer_outlined,
          isHighlight: true,
        ),
        _buildTelemetryCard(
          'TRAP SPEED',
          '152.8',
          'km/h',
          Icons.speed,
          isHighlight: false,
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(
    String title,
    String value,
    String unit,
    IconData icon, {
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFDE8E8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? AppColors.primaryMaroon : AppColors.borderLight,
          width: isHighlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? AppColors.primaryMaroon
                      : AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isHighlight ? AppColors.primaryMaroon : Colors.orange,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isHighlight
                      ? AppColors.primaryMaroon
                      : AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? AppColors.primaryMaroon
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 7. WATERMARK TIMING SYSTEM ---
  Widget _buildTimingWatermark() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderLight, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'APEX TIMING SYSTEM • 201M',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderLight, thickness: 1),
        ),
      ],
    );
  }

  // --- 8. TOMBOL BAGIKAN TIME SLIP ---
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _showMessage('Membuka dialog bagikan Time Slip...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.share, size: 18, color: Colors.white),
        label: const Text(
          'BAGIKAN TIME SLIP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
