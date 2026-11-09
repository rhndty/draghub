# Panduan Pembagian Kerja & Standar Git Pull Request
## DragHub Mobile Team (Kolaborasi 5 Developer)
**Anggota Tim:** Rafli (Lead), Dika, Alfa, Raihan, Ferdi  
**Versi:** 1.2 (Scrutineering Verification & Disqualification Assignment)  
**Dokumen Terkait:** [PRD_DragHub.md](PRD_DragHub.md) | [ERD_DragHub.md](ERD_DragHub.md)

---

## 1. Pemetaan Peran & Tanggung Jawab Modul (Teknis vs Komunitas)

| Anggota Tim | Jabatan Komunitas | Track Teknis | Modul Fitur & Penugasan Spesifik |
| :--- | :--- | :--- | :--- |
| **Rafli** *(Lead)* | **Ketua (President)** | **Core Architecture & RBAC** | • Arsitektur folder & Data Models inti (`user_model.dart`, `motorcycle_model.dart`)<br>• Gatekeeper Git (Review & Merge PR ke `main`)<br>• Approval pengesahan event resmi yang dibuat Sekretaris<br>• Monitoring log audit diskualifikasi peserta |
| **Dika** | **Bendahara** | **Finansial & Verifikasi Pembayaran** | • **Verifikasi Pembayaran Pendaftaran:** Memeriksa bukti transfer struk bank di `tab_kas_view.dart`<br>• **Penerbitan Nomor Balap:** Saat Dika klik "Verifikasi Lunas", sistem otomatis mengaktifkan Nomor Balap (`assignedStartNumber`) untuk pembalap<br>• Rekapitulasi kas masuk/keluar komunitas *(Bendahara TIDAK mengurusi teknis mesin)* |
| **Alfa** | **Sekretaris** | **Event & Scrutineering Meja Paddock** | • Form pembuatan event & penentuan kelas balap berbasis batas diameter piston di `tab_event_view.dart`<br>• **Fitur Validasi Scrutineering Fisik:** Input hasil ukur aktual piston (`measuredPistonMm`) di meja paddock<br>• **Mekanisme Dialog Konfirmasi Diskualifikasi:** Menampilkan modal dialog peringatan bertingkat + input wajib berita acara alasan diskualifikasi jika motor overspec |
| **Raihan** | **Wakil Ketua / Ofisial** | **Telemetri & Leaderboard** | • Form input telemetri balap per lintasan (*Lane 01/02*, Reaction Time, Elapsed Time) di `tab_telemetri_view.dart`<br>• Filter peserta balap: Hanya nomor balap yang **LUNAS** dan **LOLOS SCRUTINEERING** yang boleh dicatat waktunya di leaderboard<br>• Tampilan klasemen realtime (`leaderboard_screen.dart`) |
| **Ferdi** | **Anggota (Pembalap)** | **Rider Experience & Profil Motor** | • **Form Profil Motor Pembalap:** Input Merk (Honda/Yamaha/Suzuki/Vespa), Nama Kendaraan (Vario/Sprint/Aerox/dll), Tipe (Matic/Kopling), dan Diameter Piston (59/60/62/63/66 mm)<br>• Alur daftar kelas event & upload foto bukti bayar<br>• Tampilan kartu balap pembalap: Nomor balap resmi dan status inspeksi (Badge Hijau: *Lolos Scrut*, Badge Merah: *Diskualifikasi beserta alasannya*) |

---

## 2. Pemetaan Kepemilikan File (File Ownership Matrix)

Untuk mencegah terjadinya *merge conflict*, setiap developer fokus pada file-nya masing-masing:

```
lib/
├── models/
│   ├── user_model.dart            <-- Rafli
│   ├── motorcycle_model.dart      <-- Rafli & Ferdi
│   ├── kas_model.dart             <-- Dika
│   ├── event_model.dart           <-- Alfa
│   └── race_result_model.dart     <-- Raihan
├── services/
│   ├── auth_service.dart          <-- Rafli
│   ├── kas_service.dart           <-- Dika (Logika verifikasi pembayaran & kas)
│   ├── event_service.dart         <-- Alfa (Logika batas piston, event & scrutineering)
│   └── telemetry_service.dart     <-- Raihan (Logika telemetri & timing)
├── screens/
│   ├── login_screen.dart          <-- Rafli
│   ├── register_screen.dart       <-- Ferdi
│   ├── home_screen.dart           <-- Ferdi (Profil motor & tampilan badge status scrut)
│   ├── leaderboard_screen.dart    <-- Raihan
│   └── panitia/
│       ├── tab_kas_view.dart      <-- Dika (Verifikasi bayar -> generate nomor balap)
│       ├── tab_event_view.dart    <-- Alfa (Form event & modal konfirmasi diskualifikasi scrut)
│       └── tab_telemetri_view.dart<-- Raihan (Input waktu balap berdasarkan nomor balap)
└── widgets/                       <-- Komponen bersama
```

---

## 3. Protokol Git & Pull Request (Aturan 5 Developer)

### 3.1 Tiga Aturan Emas
1. **Dilarang Push Langsung ke `main`:** Semua perubahan masuk melalui Pull Request (PR).
2. **Satu Fitur = Satu Branch:** 
   * `feat/nama-fitur-nama` (contoh: `feat/motor-form-ferdi`, `feat/scrut-dialog-alfa`, `feat/verifikasi-bayar-dika`)
   * `fix/nama-bug-nama`
   * `refactor/nama-modul-nama`
3. **Peer Review Wajib:** 
   * **Dika (Bendahara)** saling review dengan **Ferdi (Pembalap)** *(karena urusan verifikasi transfer & nomor balap)*.
   * **Alfa (Sekretaris)** saling review dengan **Raihan (Ofisial)** *(karena urusan validasi scrutineering piston & telemetri)*.
   * **Rafli (Lead)** melakukan *Final Check & Merge*.

---

### 3.2 Alur Kerja Harian Terminal Git

1. **Tarik Kode Terbaru:**
   ```bash
   git checkout main
   git pull origin main
   ```
2. **Buat Branch Fitur:**
   ```bash
   git checkout -b feat/tugas-saya-nama
   ```
3. **Kerjakan & Commit Berkala:**
   ```bash
   git add .
   git commit -m "feat(scrut): implementasi modal konfirmasi diskualifikasi overspec piston"
   ```
4. **Push ke GitHub & Buka Pull Request:**
   ```bash
   git push -u origin feat/tugas-saya-nama
   ```
5. **Review & Merge:** Setelah di-approve oleh reviewer dan Rafli, merge ke `main`.
