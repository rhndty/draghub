import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'admin_financial_screen.dart';

class AdminEventScreen extends StatefulWidget {
  const AdminEventScreen({super.key});

  @override
  State<AdminEventScreen> createState() => _AdminEventScreenState();
}

class _AdminEventScreenState extends State<AdminEventScreen> {
  // State untuk kontrol interaktif
  bool _isTrackHot = true;
  bool _sensorChecked = true;
  bool _medicalChecked = true;
  bool _scrutChecked = true;
  int _adminNavIndex = 0;

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
            const SizedBox(height: 16),
            _buildCircuitStatusWidget(),
            const SizedBox(height: 16),
            _buildMainActionButtons(),
            const SizedBox(height: 24),
            _buildQuotaManagementSection(),
            const SizedBox(height: 24),
            _buildInspectionChecklist(),
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
                'RACE DIRECTOR',
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

  // --- 2. HEADER PERAN (ROLE) ---
  Widget _buildRoleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMaroon,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PERAN: RACE DIRECTOR & ADMIN',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryMaroon,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.dns_outlined,
                    size: 10,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SYS-RD-992',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Race Director',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 12,
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 1.0,
                    ),
                  ),
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
            Expanded(
              child: Text(
                'Otorisasi Tingkat 1 • Regulasi sirkuit, telemetri, & alokasi start',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
            Text(
              'MASTER\nCONSOLE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.textBadge,
                letterSpacing: 1.0,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. WIDGET STATUS SIRKUIT (HOT TRACK) ---
  Widget _buildCircuitStatusWidget() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isTrackHot
                      ? AppColors.primaryMaroon
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'CIRCUIT STATUS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
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
                            color: AppColors.segmentBackground,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '402M',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sentul 402m Dra...',
                      style: TextStyle(
                        fontSize: 13,
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
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isTrackHot
                      ? AppColors.primaryMaroon
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isTrackHot ? 'HOT TRACK' : 'RED FLAG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildWeatherMetric(
                    Icons.thermostat,
                    'ASPAL',
                    '32.4°C',
                    'Grip Optimal',
                    const Color(0xFF2E7D32),
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.borderLight),
                Expanded(
                  child: _buildWeatherMetric(
                    Icons.air,
                    'ANGIN',
                    '4.2 m/s',
                    'Headwind NW',
                    AppColors.textMuted,
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.borderLight),
                Expanded(
                  child: _buildWeatherMetric(
                    Icons.water_drop_outlined,
                    'LEMBAB',
                    '62%',
                    'Density: 1.18',
                    AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isTrackHot = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isTrackHot
                          ? AppColors.primaryMaroon
                          : AppColors.segmentBackground,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 14,
                          color: _isTrackHot
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'TRACK OPEN / HOT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _isTrackHot
                                ? Colors.white
                                : AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isTrackHot = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isTrackHot
                          ? AppColors.textBadge
                          : AppColors.segmentBackground,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.do_not_disturb_alt,
                          size: 14,
                          color: !_isTrackHot
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'RED FLAG / CLOSED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: !_isTrackHot
                                ? Colors.white
                                : AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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

  Widget _buildWeatherMetric(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color subtitleColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 10, color: AppColors.primaryMaroon),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 8,
            color: subtitleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- 4. TOMBOL AKSI UTAMA ---
  Widget _buildMainActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'BUAT EVENT DRAG BARU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionButton(
                Icons.edit_calendar,
                'EDIT EVENT',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSecondaryActionButton(Icons.menu_book, 'REGULASI'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSecondaryActionButton(
                Icons.file_download_outlined,
                'EKSPOR',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 12, color: AppColors.primaryMaroon),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- 5. MANAJEMEN KUOTA KELAS BALAP ---
  Widget _buildQuotaManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.people_outline,
                  color: AppColors.primaryMaroon,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Manajemen Kuota Kelas Balap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.segmentBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '4 KELAS AKTIF',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Kartu Kelas Balap Sesuai Desain
        _buildClassQuotaCard(
          className: 'Bebek 4T TU 200cc',
          badgeText: 'ON1',
          badgeColor: AppColors.primaryMaroon,
          badgeBgColor: const Color(0xFFFDF2F2),
          filled: 28,
          total: 30,
          percentage: 93,
          subtitle: 'Bobot min. 105kg - Paddock Blok A',
          bottomLeftText: '2 Slot tersisa',
          actionButtons: [
            _buildSmallOutlineButton(
              Icons.add,
              '+5 SLOT',
              AppColors.primaryMaroon,
            ),
            const SizedBox(width: 8),
            _buildSmallOutlineButton(
              Icons.lock_outline,
              'KUNCI KELAS',
              AppColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildClassQuotaCard(
          className: 'Sport 2T Frame STD 155cc',
          badgeText: 'PENUH',
          badgeColor: AppColors.primaryMaroon,
          badgeBgColor: const Color(0xFFFDF2F2),
          filled: 32,
          total: 32,
          percentage: 100,
          subtitle: 'Regulasi Ninja Open Rangka Standar Pabrik',
          bottomLeftText: 'Antrian: 4 Starter',
          bottomLeftIcon: Icons.hourglass_empty,
          actionButtons: [
            _buildSmallOutlineButton(
              Icons.list_alt,
              'BUKA WAITING LIST',
              AppColors.primaryMaroon,
              bgColor: const Color(0xFFFDF2F2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildClassQuotaCard(
          className: 'FFA 4T 350cc',
          badgeText: 'BUKA',
          badgeColor: const Color(0xFF2E7D32),
          badgeBgColor: const Color(0xFFE8F5E9),
          filled: 18,
          total: 25,
          percentage: 72,
          subtitle: 'Batas pendaftaran resmi: H-1 (23:59 WIB)',
          bottomLeftText: '7 slot tersisa',
          actionButtons: [
            _buildSmallOutlineButton(
              Icons.timer_off_outlined,
              'TUTUP LEBIH AWAL',
              AppColors.primaryMaroon,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildClassQuotaCard(
          className: 'Bebek 2T 130cc Tune Up',
          badgeText: 'UPCOMING',
          badgeColor: AppColors.textMuted,
          badgeBgColor: AppColors.segmentBackground,
          filled: 24,
          total: 30,
          percentage: 80,
          subtitle: 'Scrutineering dimulai 07:30 WIB',
          bottomLeftText: '6 slot tersisa',
          actionButtons: [
            _buildSmallOutlineButton(
              Icons.fact_check_outlined,
              'AUDIT STARTER',
              AppColors.textDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassQuotaCard({
    required String className,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    required int filled,
    required int total,
    required int percentage,
    required String subtitle,
    required String bottomLeftText,
    IconData? bottomLeftIcon,
    required List<Widget> actionButtons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
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
                        Flexible(
                          child: Text(
                            className,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$filled/$total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$percentage% TERISI',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: percentage == 100
                          ? AppColors.primaryMaroon
                          : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
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
              Row(
                children: [
                  if (bottomLeftIcon != null) ...[
                    Icon(bottomLeftIcon, size: 10, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    bottomLeftText,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(children: actionButtons),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallOutlineButton(
    IconData icon,
    String label,
    Color color, {
    Color bgColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color == AppColors.textMuted
              ? AppColors.borderLight
              : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. INSPEKSI KESIAPAN SIRKUIT ---
  Widget _buildInspectionChecklist() {
    int checkedCount =
        (_sensorChecked ? 1 : 0) +
        (_medicalChecked ? 1 : 0) +
        (_scrutChecked ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primaryMaroon,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Inspeksi Kesiapan Sirkuit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$checkedCount/3 LOLOS',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildChecklistItem(
          title: 'Sensor Chrono & Tree Light',
          subtitle: 'Laser photogate 60ft, 201m, 402m terkalibrasi',
          value: _sensorChecked,
          onChanged: (val) => setState(() => _sensorChecked = val ?? false),
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          title: 'Tim Medis & Safety Car',
          subtitle: '2 Unit Ambulans + APAR foam 50L siaga di ujung runoff',
          value: _medicalChecked,
          onChanged: (val) => setState(() => _medicalChecked = val ?? false),
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          title: 'Scrutineering Bay Terbuka',
          subtitle: 'Timbangan digital & buret kubikasi siap operasi',
          value: _scrutChecked,
          onChanged: (val) => setState(() => _scrutChecked = val ?? false),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              activeColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (value)
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
        ],
      ),
    );
  }
}
