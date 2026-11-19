import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AdminTimingScreen extends StatefulWidget {
  const AdminTimingScreen({super.key});

  @override
  State<AdminTimingScreen> createState() => _AdminTimingScreenState();
}

class _AdminTimingScreenState extends State<AdminTimingScreen> {
  int _adminNavIndex = 2; // 2 = Timing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAdminAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoleHeader(),
            const SizedBox(height: 20),
            _buildLiveHeatConsole(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentLogSection(),
            const SizedBox(height: 24),
            _buildLiveFeedCam(),
            const SizedBox(height: 24),
            _buildPublishFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 1. APP BAR KHUSUS ADMIN ---
  PreferredSizeWidget _buildAdminAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'RACE CONTROL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
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
            border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
          ),
          child: Row(
            children: const [
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
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryMaroon,
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryMaroon,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // --- 2. HEADER PERAN & SINKRONISASI ---
  Widget _buildRoleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryMaroon.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMaroon,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PERAN: RACE CONTROL TIMING',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryMaroon,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.sensors, size: 10, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'GATE OPTIC 201M',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Race Control',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Precision Drag Timing Console • Sentinel v4.8',
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.compare_arrows,
                      size: 12,
                      color: AppColors.primaryMaroon,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'SYNC',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryMaroon,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '±0.0001s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LIVE CHRONO FEED',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. KONSOL HEAT AKTIF ---
  Widget _buildLiveHeatConsole() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Kelas & Heat
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'HEAT 02 • PENYISIHAN',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryMaroon,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Text(
                              '201M',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sport 2T Frame STD ...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'GRN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lane A (Pemenang)
          _buildLaneCard(
            laneLabel: 'LANE A',
            isLaneA: true,
            startNumber: '#79',
            racerName: 'Eko Chodox',
            rt: '0.042',
            rtColor: const Color(0xFF2E7D32),
            ft60: '1.621s',
            et: '6.912s',
            topSpd: '158',
            spdUnit: 'KM/H',
            statusWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.emoji_events, size: 10, color: Color(0xFF2E7D32)),
                  SizedBox(width: 4),
                  Text(
                    'WIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Lane B (Jump Start)
          _buildLaneCard(
            laneLabel: 'LANE B',
            isLaneA: false,
            startNumber: '#44',
            racerName: 'Dwi Batank',
            rt: '-0.015',
            rtColor: Colors.red,
            ft60: '--.---',
            et: 'JUMP ST',
            etLabel: 'STATUS',
            etColor: Colors.red,
            topSpd: 'DSQ',
            spdUnit: '',
            spdLabel: 'PENALTI',
            spdColor: Colors.red,
            statusWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'RED LIGHT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Delta / Selisih Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'GATE TIMING DELTA',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'SENSOR',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(
                    Icons.keyboard_double_arrow_up,
                    size: 12,
                    color: AppColors.textDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '0.057s FOUL\nADVANTAGE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar Delta
          Row(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMaroon,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaneCard({
    required String laneLabel,
    required bool isLaneA,
    required String startNumber,
    required String racerName,
    required String rt,
    required Color rtColor,
    required String ft60,
    required String et,
    String etLabel = 'ET 201M',
    Color etColor = AppColors.textDark,
    required String topSpd,
    required String spdUnit,
    String spdLabel = 'TOP SPD',
    Color spdColor = AppColors.textDark,
    required Widget statusWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLaneA
                          ? AppColors.primaryMaroon
                          : const Color(0xFF455A64),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      laneLabel,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    startNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    racerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              statusWidget,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTimingMetric('RT (S)', rt, rtColor)),
              Container(width: 1, height: 30, color: AppColors.borderLight),
              Expanded(
                child: _buildTimingMetric('60 FT', ft60, AppColors.textDark),
              ),
              Container(width: 1, height: 30, color: AppColors.borderLight),
              Expanded(child: _buildTimingMetric(etLabel, et, etColor)),
              Container(width: 1, height: 30, color: AppColors.borderLight),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      spdLabel,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topSpd,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: spdColor,
                      ),
                    ),
                    if (spdUnit.isNotEmpty)
                      Text(
                        spdUnit,
                        style: const TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- 4. TINDAKAN CEPAT ---
  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'TINDAKAN CEPAT HEAT',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'CHRONO-LOCK: ACTIVE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.verified, size: 14, color: Colors.white),
            label: const Text(
              'SAHKAN HASIL HEAT 02',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_note,
                  size: 14,
                  color: AppColors.textDark,
                ),
                label: const Text(
                  'INPUT WAKTU MANUAL',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: AppColors.primaryMaroon,
                ),
                label: const Text(
                  'FLAG INVESTIGASI',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 5. LOG WAKTU TERKINI ---
  Widget _buildRecentLogSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Row(
              children: [
                Icon(Icons.history, size: 14, color: AppColors.primaryMaroon),
                SizedBox(width: 6),
                Text(
                  'LOG WAKTU TEMPUH TERKINI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              'REFRESH: 50Hz',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLogItem(
          'H-08',
          '#88',
          'Bayu Pratama',
          'Lolos ke Final',
          const Color(0xFF2E7D32),
          '07.104s',
          true,
        ),
        _buildLogItem(
          'H-07',
          '#118',
          'Ahmad Rifai',
          'Peringkat 4',
          const Color(0xFF2E7D32),
          '07.240s',
          false,
        ),
        _buildLogItem(
          'H-06',
          '#21',
          'Fandi Ahmad',
          'Peringkat 2',
          const Color(0xFF2E7D32),
          '07.189s',
          false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildLogItem(
    String heat,
    String startNumber,
    String name,
    String status,
    Color statusColor,
    String time,
    bool isTop, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              heat,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryMaroon,
              ),
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
                      startNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'VALID SCORE',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. LIVE FEED CAMERA ---
  Widget _buildLiveFeedCam() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TRACK CAM 01 • FINISH LINE TRAPS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE FEED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.textDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1541343672885-9be56236302a?q=80&w=600&auto=format&fit=crop',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '201.00 METER PHOTOCELL BEAM OPTICAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                    Text(
                      'ALIGNED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 7. PUBLISH FOOTER ---
  Widget _buildPublishFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.publish_outlined,
                    size: 16,
                    color: AppColors.primaryMaroon,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PUBLISH HASIL KE LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'LEADERBOARD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'PUSH\nNOTIF',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.verified_user_outlined,
              size: 10,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 4),
            Text(
              'VERIFIED RACE MARSHAL CRYPTOGRAPHIC SIGNATURE',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
