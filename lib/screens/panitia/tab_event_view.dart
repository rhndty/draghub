import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/event_card.dart';

/// Tab Form & Manajemen Draft Event (Modul Milik Alfa / Sekretaris)
/// Berfungsi untuk menyusun draft kejuaraan, menentukan kelas & braket, serta memantau status persetujuan.
class TabEventView extends StatefulWidget {
  const TabEventView({super.key});

  @override
  State<TabEventView> createState() => _TabEventViewState();
}

class _TabEventViewState extends State<TabEventView> {
  final EventService _eventService = EventService();
  String _filterStatus = 'ALL';

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCreateDraftDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateEventBottomSheet(
        onEventCreated: () {
          _showMessage('Draft event berhasil disimpan! Menunggu approval Ketua/Wakil.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Sekretaris
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MANAJEMEN EVENT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Modul Sekretaris • Draft Regulasi Balap',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreateDraftDialog,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'BUAT DRAFT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Status Event
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'SEMUA'),
                  _buildFilterChip('DRAFT', 'DRAFT'),
                  _buildFilterChip('PUBLISHED', 'PUBLIK/BUKA'),
                  _buildFilterChip('ONGOING', 'LIVE'),
                  _buildFilterChip('COMPLETED', 'SELESAI'),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // Daftar Event
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: _eventService.getEventsStream(
                  status: _filterStatus == 'ALL' ? null : _filterStatus,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'),
                    );
                  }

                  final events = snapshot.data ?? [];
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 54, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada event dalam kategori ini',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Klik tombol "BUAT DRAFT" di atas untuk menyusun agenda balap baru.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final item = events[index];
                      return EventCard(
                        event: item,
                        actionButtonText: item.isDraft ? 'DRAFT MENUNGGU PERSETUJUAN KETUA' : null,
                        onActionButtonPressed: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primaryMaroon,
        backgroundColor: AppColors.segmentBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        onSelected: (_) => setState(() => _filterStatus = value),
      ),
    );
  }
}

/// BottomSheet Formulir Pembuatan Draft Event (Sesuai 1 Event = 1 Kelas)
class _CreateEventBottomSheet extends StatefulWidget {
  final VoidCallback onEventCreated;

  const _CreateEventBottomSheet({required this.onEventCreated});

  @override
  State<_CreateEventBottomSheet> createState() => _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<_CreateEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController(
    text: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=600&auto=format&fit=crop',
  );
  final TextEditingController _feeCtrl = TextEditingController(text: '250000');
  final TextEditingController _quotaCtrl = TextEditingController(text: '50');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _vehicleType = 'MATIC'; // 'MATIC' | 'KOPLING'
  double _maxPistonDiameterMm = 63.0; // 59, 62, 63, 66
  double _bracketSeconds = 7.0; // 7, 8, 9

  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _imageCtrl.dispose();
    _feeCtrl.dispose();
    _quotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDraft() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.createEventDraft(
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        eventDate: _selectedDate,
        imageUrl: _imageCtrl.text.trim(),
        vehicleType: _vehicleType,
        maxPistonDiameterMm: _maxPistonDiameterMm,
        bracketSeconds: _bracketSeconds,
        registrationFee: int.tryParse(_feeCtrl.text.replaceAll('.', '')) ?? 0,
        quota: int.tryParse(_quotaCtrl.text) ?? 50,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onEventCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan draft: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Formulir Draft Event Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                '1 Event = 1 Kelas. Ditentukan oleh tipe kendaraan, batas piston, & braket waktu.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Judul & Lokasi
              _buildTextField('Judul Kejuaraan/Latber', _titleCtrl, 'Contoh: Drag Fest Ramadhan 201m'),
              const SizedBox(height: 12),
              _buildTextField('Lokasi Sirkuit / Paddock', _locationCtrl, 'Contoh: Sirkuit Meikarta Non-Permanen'),
              const SizedBox(height: 12),

              // Tanggal Event
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, size: 16, color: AppColors.primaryMaroon),
                      label: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Spesifikasi Kelas: Tipe Kendaraan
              const Text(
                'TIPE KENDARAAN (KELAS BALAP)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('MATIC')),
                      selected: _vehicleType == 'MATIC',
                      selectedColor: AppColors.primaryMaroon,
                      labelStyle: TextStyle(
                        color: _vehicleType == 'MATIC' ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() {
                        _vehicleType = 'MATIC';
                        _maxPistonDiameterMm = 63.0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('KOPLING')),
                      selected: _vehicleType == 'KOPLING',
                      selectedColor: AppColors.primaryMaroon,
                      labelStyle: TextStyle(
                        color: _vehicleType == 'KOPLING' ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() {
                        _vehicleType = 'KOPLING';
                        _maxPistonDiameterMm = 66.0;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Batas Piston & Braket Waktu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BATAS PISTON MAKSIMAL',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<double>(
                          value: _maxPistonDiameterMm,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 59.0, child: Text('59 mm')),
                            DropdownMenuItem(value: 60.0, child: Text('60 mm')),
                            DropdownMenuItem(value: 62.0, child: Text('62 mm')),
                            DropdownMenuItem(value: 63.0, child: Text('63 mm')),
                            DropdownMenuItem(value: 66.0, child: Text('66 mm')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _maxPistonDiameterMm = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BRAKET WAKTU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<double>(
                          value: _bracketSeconds,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 7.0, child: Text('7.0 Detik')),
                            DropdownMenuItem(value: 7.5, child: Text('7.5 Detik')),
                            DropdownMenuItem(value: 8.0, child: Text('8.0 Detik')),
                            DropdownMenuItem(value: 8.5, child: Text('8.5 Detik')),
                            DropdownMenuItem(value: 9.0, child: Text('9.0 Detik')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _bracketSeconds = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Biaya & Kuota
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Biaya Pendaftaran (Rp)',
                      _feeCtrl,
                      '250000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'Kuota Peserta',
                      _quotaCtrl,
                      '50',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildTextField('URL Poster Event (Cloudinary)', _imageCtrl, 'https://...'),
              const SizedBox(height: 20),

              // Tombol Simpan Draft
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'SIMPAN DRAFT KEJUARAAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Kolom ini wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }
}

