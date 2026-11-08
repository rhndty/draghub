import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';

/// Tab Input Telemetri & Klasemen Balap (Modul Milik Raihan / Wakil Ketua & Ofisial)
class TabTelemetriView extends StatefulWidget {
  const TabTelemetriView({super.key});

  @override
  State<TabTelemetriView> createState() => _TabTelemetriViewState();
}

class _TabTelemetriViewState extends State<TabTelemetriView> {
  final TextEditingController _startNumberController = TextEditingController();
  final TextEditingController _reactionTimeController = TextEditingController();
  final TextEditingController _elapsedTimeController = TextEditingController();

  String _selectedLane = 'LANE 01';
  String _selectedStage = 'QUALIFYING';
  String? _selectedEventId;
  bool _isSavingTime = false;

  @override
  void dispose() {
    _startNumberController.dispose();
    _reactionTimeController.dispose();
    _elapsedTimeController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveRaceResult() async {
    final startNum = _startNumberController.text.trim();
    final rtText = _reactionTimeController.text.trim();
    final etText = _elapsedTimeController.text.trim();

    if (startNum.isEmpty || rtText.isEmpty || etText.isEmpty) {
      _showMessage('Harap isi Nomor Start, Reaction Time, dan Elapsed Time.', isError: true);
      return;
    }

    final double? rt = double.tryParse(rtText);
    final double? et = double.tryParse(etText);

    if (rt == null || et == null) {
      _showMessage('Format angka RT atau ET tidak valid.', isError: true);
      return;
    }

    setState(() => _isSavingTime = true);

    try {
      final double totalTime = double.parse((rt + et).toStringAsFixed(3));
      final formattedStartNum = startNum.startsWith('#') ? startNum : '#$startNum';

      await FirebaseFirestore.instance.collection('race_results').add({
        'eventId': _selectedEventId ?? '',
        'startNumber': formattedStartNum,
        'lane': _selectedLane,
        'stage': _selectedStage,
        'reactionTime': rt,
        'elapsedTime': et,
        'totalTime': totalTime,
        'userId': '',
        'registrationId': '',
        'classId': '',
        'recordedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Hasil balap $formattedStartNum ($totalTime s) berhasil dicatat!');
      _startNumberController.clear();
      _reactionTimeController.clear();
      _elapsedTimeController.clear();
    } catch (e) {
      _showMessage('Gagal menyimpan hasil balap: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingTime = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.speed,
          'INPUT WAKTU TELEMETRI RESMI',
          'PENCATATAN HASIL',
        ),
        const SizedBox(height: 14),

        // Kartu Form Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilih Event
              const Text('EVENT BALAPAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(color: AppColors.primaryMaroon);
                  }
                  final events = snapshot.data!.docs;
                  if (events.isEmpty) {
                    return const Text('Tidak ada event aktif', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
                  }

                  _selectedEventId ??= events.first.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedEventId,
                        items: events.map((e) {
                          final eventData = e.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(
                              '${eventData['title'] ?? 'Kejuaraan'} (${eventData['status'] ?? ''})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedEventId = val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Nomor Start & Jalur (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NOMOR START', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _startNumberController,
                          hintText: '#402',
                          prefixIcon: Icons.tag,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('JALUR (LANE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.segmentBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedLane,
                              items: const [
                                DropdownMenuItem(value: 'LANE 01', child: Text('LANE 01', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'LANE 02', child: Text('LANE 02', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) => setState(() => _selectedLane = val ?? 'LANE 01'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Babak (Stage)
              const Text('BABAK (STAGE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.segmentBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedStage,
                    items: const [
                      DropdownMenuItem(value: 'QUALIFYING', child: Text('QUALIFYING (Penyisihan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 'FINAL', child: Text('FINAL (Babak Utama)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) => setState(() => _selectedStage = val ?? 'QUALIFYING'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Reaction Time & Elapsed Time (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REACTION TIME (s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _reactionTimeController,
                          hintText: '0.038',
                          prefixIcon: Icons.bolt,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ELAPSED TIME (s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _elapsedTimeController,
                          hintText: '07.189',
                          prefixIcon: Icons.timer,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSavingTime ? null : _saveRaceResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isSavingTime
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, color: Colors.white, size: 18),
                  label: Text(
                    _isSavingTime ? 'MENYIMPAN TELEMETRI...' : 'SIMPAN KE LEADERBOARD',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Riwayat Catatan Balap Terkini
        _buildSectionHeader(
          Icons.history,
          'CATATAN WAKTU TERBARU',
          'REALTIME TELEMETRI',
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('race_results')
              .orderBy('recordedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primaryMaroon)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCard('Belum ada catatan waktu yang diinput.');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildResultHistoryItem(data, doc.id);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildResultHistoryItem(Map<String, dynamic> data, String docId) {
    final startNum = data['startNumber'] ?? '#---';
    final lane = data['lane'] ?? 'LANE';
    final stage = data['stage'] ?? 'RACE';
    final total = data['totalTime'] != null ? '${data['totalTime']}s' : '-';
    final rt = data['reactionTime'] != null ? '${data['reactionTime']}s' : '-';
    final et = data['elapsedTime'] != null ? '${data['elapsedTime']}s' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryMaroon,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  startNum,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$lane • $stage',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  Text(
                    'RT: $rt | ET: $et',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                total,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryMaroon,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('race_results').doc(docId).delete();
                  _showMessage('Catatan waktu dihapus.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryMaroon, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 0.5),
            ),
          ],
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

