import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '';

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  bool _isSaving = false;

  // Controllers Informasi Pokok (Dikosongkan agar tidak hardcode)
  final TextEditingController _eventNameCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _timeCtrl = TextEditingController();

  // State Jarak Tempuh & Regulasi
  bool _is201m = true;
  final TextEditingController _weightToleranceCtrl = TextEditingController(
    text: '0.5',
  ); // Default toleransi
  String _timingSystem = 'Laser Chrono Optic Sentinel v4.8 (IMI Homologated)';

  // Toggles
  bool _allowOTS = true;
  bool _lockBikeH1 = true;
  bool _requireIMI = true;

  // List Kelas Dinamis (Tidak lagi di-hardcode)
  // Kita sisakan 1 sebagai contoh default agar desain terlihat
  List _classes = [
    {'name': 'Bebek 4T TU 200cc', 'max': 30, 'price': 'Rp 700.000'},
  ];

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _weightToleranceCtrl.dispose();
    super.dispose();
  }

  // --- FUNGSI DINAMIS UNTUK CRUD KELAS BALAP ---

  void _showAddEditClassDialog({int? index}) {
    final isEdit = index != null;

    // Inisialisasi controller dialog
    final nameCtrl = TextEditingController(
      text: isEdit ? _classes[index]['name'] : '',
    );
    final maxCtrl = TextEditingController(
      text: isEdit ? _classes[index]['max'].toString() : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? _classes[index]['price'] : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.add_circle,
              color: AppColors.primaryMaroon,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'Edit Kelas Balap' : 'Tambah Kelas Baru',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                labelStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maksimal Starter',
                labelStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Biaya Pendaftaran (Contoh: Rp 700.000)',
                labelStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryMaroon),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'BATAL',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              elevation: 0,
            ),
            onPressed: () {
              setState(() {
                final newClass = {
                  'name': nameCtrl.text.trim().isEmpty
                      ? 'Kelas Baru'
                      : nameCtrl.text.trim(),
                  'max': int.tryParse(maxCtrl.text.trim()) ?? 0,
                  'price': priceCtrl.text.trim().isEmpty
                      ? 'Rp 0'
                      : priceCtrl.text.trim(),
                };

                if (isEdit) {
                  _classes[index] = newClass;
                } else {
                  _classes.add(newClass);
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              'SIMPAN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteClass(int index) {
    setState(() {
      _classes.removeAt(index);
    });
  }

  // --- FUNGSI PUBLISH EVENT KE FIRESTORE ---

  Future<void> _publishEvent() async {
    if (_eventNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama event tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. Simpan ke koleksi 'events'
      DocumentReference eventRef = await FirebaseFirestore.instance
          .collection('events')
          .add({
            'title': _eventNameCtrl.text.trim(),
            'location': _locationCtrl.text.trim().isNotEmpty
                ? _locationCtrl.text.trim()
                : 'Lokasi Belum Ditentukan',
            'eventSchedule': _dateCtrl.text.trim(),
            'distanceMeter': _is201m ? 201 : 402,
            'eventDate': FieldValue.serverTimestamp(),
            'status': 'UPCOMING',
            'quotaTotal': _classes.fold(
              0,
              (sum, item) => sum + (item['max'] as int),
            ),
            'quotaFilled': 0,
            'timingSystem': _timingSystem,
            'allowOTS': _allowOTS,
            'lockBikeH1': _lockBikeH1,
            'requireIMI': _requireIMI,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Simpan kelas ke subcollection 'classes'
      for (var cls in _classes) {
        await eventRef.collection('classes').add({
          'className': cls['name'],
          'maxStarter': cls['max'],
          'price': cls['price'],
          'registeredCount': 0, // Awal daftar masih 0
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event Resmi Diterbitkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerbitkan event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BUAT EVENT BARU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'RACE DIRECTOR • NEW EVENT SETUP',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryMaroon,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFFDF2F2),
              child: Icon(
                Icons.person,
                color: AppColors.primaryMaroon,
                size: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildDraftAlert(),
            const SizedBox(height: 16),
            _buildVisualPoster(),
            const SizedBox(height: 16),
            _buildSection01(),
            const SizedBox(height: 16),
            _buildSection02(),
            const SizedBox(height: 16),
            _buildSection03(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            const Text(
              'APEX RACE MANAGEMENT SYSTEM • IMI CERTIFIED\nTELEMETRY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildDraftAlert() {
    // Membuat draft code dinamis berdasarkan Tahun & Bulan saat ini
    final now = DateTime.now();
    final months = [
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
    final draftCode = 'EVT-DRG-\n${now.year}-${months[now.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMaroon.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DRAFT MODE • EVENT SETUP',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryMaroon,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'SERI\nBARU\n(03)',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  draftCode,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.primaryMaroon,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Parameter teknis, regulasi IMI, dan alokasi kuota kelas akan disimpan otomatis sebagai draft sebelum resmi dipublikasikan ke aplikasi paddock peserta.',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPoster() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'KEY VISUAL EVENT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Poster Resmi Event\nBalap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Fitur unggah gambar dari galeri akan segera hadir!',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 14,
                      color: AppColors.primaryMaroon,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'UNGGAH\nPOSTER',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection01() {
    return _buildCardWrapper(
      icon: Icons.flag_outlined,
      title: 'INFORMASI POKOK',
      step: '01 / 04',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('NAMA EVENT RESMI'),
          _buildTextField(
            _eventNameCtrl,
            null,
            hintText: 'Contoh: Apex National Drag 2026',
          ),
          const SizedBox(height: 12),
          _buildInputLabel('SIRKUIT & LOKASI BALAP'),
          _buildTextField(
            _locationCtrl,
            Icons.location_on_outlined,
            hintText: 'Ketik nama sirkuit...',
          ),
          const SizedBox(height: 12),
          _buildInputLabel('KATEGORI JARAK TEMPUH LINTASAN'),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _is201m = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _is201m
                          ? AppColors.primaryMaroon
                          : AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straight,
                          size: 14,
                          color: _is201m ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '201 METER (STD)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _is201m ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _is201m = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_is201m
                          ? AppColors.primaryMaroon
                          : AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.straight,
                          size: 14,
                          color: !_is201m ? Colors.white : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '402 METER (PRO)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: !_is201m
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('JADWAL KALENDER'),
                    _buildTextField(
                      _dateCtrl,
                      Icons.calendar_today_outlined,
                      hintText: 'Tanggal Event',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('JAM OPERASIONAL PIT'),
                    _buildTextField(
                      _timeCtrl,
                      Icons.schedule,
                      hintText: 'Misal: 08:00',
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

  Widget _buildSection02() {
    return _buildCardWrapper(
      icon: Icons.checklist,
      title: 'REGULASI & TIMING SYSTEM',
      step: '02 / 04',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('SISTEM SENSOR TIMING RESMI'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.segmentBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timingSystem,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                onChanged: (String? val) =>
                    setState(() => _timingSystem = val!),
                items: [_timingSystem, 'Apex Chrono Basic v2.0']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInputLabel('TOLERANSI TIMBANGAN BOBOT SCRUTINEERING'),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.segmentBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _weightToleranceCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.scale,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      suffixText: 'kg (+ margin)',
                      suffixStyle: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'IMI APPROVED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryMaroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchItem(
            'Pendaftaran On-The-Spot (OTS)',
            'Buka loket manual registrasi paddock hari-H',
            _allowOTS,
            (v) => setState(() => _allowOTS = v),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildSwitchItem(
            'Kunci Perubahan Motor H-1',
            'Nomor rangka & spek mesin terkunci otomatis',
            _lockBikeH1,
            (v) => setState(() => _lockBikeH1 = v),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildSwitchItem(
            'Wajib Sertifikasi KTA IMI Valid',
            'Validasi lisensi pembalap otomatis via database IMI',
            _requireIMI,
            (v) => setState(() => _requireIMI = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            width: 40,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primaryMaroon,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection03() {
    return _buildCardWrapper(
      icon: Icons.flag,
      title: 'KELAS BALAP & KUOTA',
      step: '03 / 04',
      child: Column(
        children: [
          // Render daftar kelas secara dinamis
          if (_classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Belum ada kelas balap. Tambahkan sekarang.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          ..._classes.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> cls = entry.value;
            return _buildClassItem(
              index,
              cls['name'] as String,
              cls['max'] as int,
              cls['price'] as String,
            );
          }).toList(),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddEditClassDialog(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.add_circle_outline,
              size: 14,
              color: AppColors.primaryMaroon,
            ),
            label: const Text(
              'TAMBAH KELAS BALAP BARU',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryMaroon,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem(int index, String name, int maxStarter, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMaroon,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$maxStarter Starter Max',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showAddEditClassDialog(index: index),
                child: Row(
                  children: const [
                    Icon(Icons.edit, size: 10, color: AppColors.textMuted),
                    SizedBox(width: 2),
                    Text(
                      'EDIT KELAS',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _deleteClass(index),
                child: Row(
                  children: const [
                    Icon(
                      Icons.delete_outline,
                      size: 10,
                      color: AppColors.primaryMaroon,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'HAPUS',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryMaroon,
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

  // --- HELPER WIDGETS ---

  Widget _buildCardWrapper({
    required IconData icon,
    required String title,
    required String step,
    required Widget child,
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
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.primaryMaroon),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    IconData? icon, {
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 16, color: AppColors.textMuted)
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _publishEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.rocket_launch,
                    size: 14,
                    color: Colors.white,
                  ),
            label: const Text(
              'TERBITKAN EVENT SEKARANG',
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
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.save_outlined,
                  size: 12,
                  color: AppColors.primaryMaroon,
                ),
                label: const Text(
                  'SIMPAN SEBAGAI DRAFT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'BATAL',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
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
}
