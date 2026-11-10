# Panduan Pembagian Kerja & Standar Git Pull Request
## DragHub Mobile Team (Kolaborasi 5 Developer)
**Anggota Tim:** Rafli (Lead), Dika, Alfa, Raihan, Ferdi  
**Versi:** 1.3 (Disesuaikan dengan PRD v1.3.1 & ERD v1.3.1: Kuota, Nomor Urut Lunas, Kehadiran QR, Scrutineering Sebelum Balap, Podium)  
**Dokumen Terkait:** [PRD_DragHub_v1.3.md](PRD_DragHub_v1.3.md) | [ERD_DragHub_v1.3.md](ERD_DragHub_v1.3.md)

---

## 0. Ringkasan Perubahan dari v1.2

* **Satu event = satu kelas:** kelas dibentuk dari tipe kendaraan, batas piston, dan braket. Rider hanya melihat motor yang cocok saat mendaftar.
* **Nomor balap urut lunas** diterbitkan lewat satu transaksi Firestore (cek kuota, nomor, kuota terpakai, kas masuk), bukan sekadar aktivasi nomor.
* **Kehadiran QR** dan aksi **Tutup Verifikasi Kehadiran** ditambahkan.
* **Scrutineering dilakukan sebelum balap**, hanya untuk peserta lunas dan hadir. Dialog DQ adalah **satu dialog konfirmasi dengan alasan wajib** (bukan "bertingkat"). Ada **scrut ulang** oleh Ketua/Wakil dan riwayat pemeriksaan.
* **Leaderboard realtime diganti podium juara 1 sampai 3** setelah event `COMPLETED`.
* Telemetri kini mencakup braket (`BREAKOUT` otomatis), `JUMP_START`, `DNF`, satu balap per peserta, dan ringkasan konfirmasi sebelum simpan.
* Wakil (Raihan) kini memegang hak yang sama dengan Ketua untuk approve event, mulai/akhiri event, dan scrut ulang.
* Merk motor ditambah **Kawasaki**.
* Ditambahkan file dan pemilik baru untuk area yang sebelumnya tidak punya pemilik (lihat bagian 2 dan 3).

## 0.1 Setup Sebelum Pengerjaan Paralel

Kerjakan satu PR fondasi terlebih dahulu; jangan mulai fitur yang bergantung pada model bersama sebelum PR ini masuk ke `main`.

1. **Rafli menyiapkan fondasi:** struktur `models/`, `services/`, dan `screens/`; `user_model.dart`, `motorcycle_model.dart`, dan `event_registration_model.dart` mengikuti ERD; pemetaan role; kerangka `firestore.rules`; dan kontrak service yang dipakai lintas fitur. `event_model.dart` tetap milik Alfa, sedangkan `kas_model.dart` dan `race_result_model.dart` tetap milik Dika dan Raihan.
2. **Rafli mengelola perubahan dependensi bersama** di `pubspec.yaml`/`pubspec.lock`. Anggota mengajukan kebutuhan paket di PR atau koordinasi sebelum mengubah manifest, supaya perubahan lockfile tidak saling menimpa.
3. Setelah fondasi di-merge, tiap anggota membuat branch fitur sendiri dari `main`. Perubahan skema bersama tetap lewat PR dan persetujuan Rafli.
4. Jangan menyalin implementasi lama apa adanya: beberapa layar masih memakai status/field yang berbeda dari ERD v1.3.1. Migrasikan sesuai kontrak v1.3.1 saat memecah layar.

**Pemecahan layar yang disiapkan sebelum fitur paralel:**

| File saat ini | Penanganan | Pemilik |
| :--- | :--- | :--- |
| `lib/screens/home_screen.dart` (sekitar 1.240 baris) | Jadikan shell rider; pindahkan tab event mendatang, event aktif, dan bagian profil/pendaftaran ke widget atau file tab terpisah di `screens/rider/`. | Ferdi |
| `lib/screens/panitia/tab_kas_view.dart` (sekitar 647 baris) | Pisahkan verifikasi pembayaran dari tampilan/rekening kas; transaksi dan validasi dipindahkan ke `kas_service.dart`. | Dika |
| `lib/screens/panitia/tab_telemetri_view.dart` (sekitar 476 baris) | Pisahkan form input dari riwayat hasil; perhitungan status dan penyimpanan berada di `telemetry_service.dart`. | Raihan |
| `lib/screens/leaderboard_screen.dart` (sekitar 665 baris) | Ganti dengan `podium_screen.dart` sesuai PRD; jangan mempertahankan leaderboard realtime lama. | Raihan |

Pemecahan dilakukan bertahap dalam PR pemilik masing-masing, tidak dalam satu PR lintas tim. Tunda pemisahan bila menghalangi fondasi; yang wajib sebelum merge fitur adalah setiap modul punya pemilik tunggal dan aturan bisnis tidak tertanam di widget.

---

## 1. Pemetaan Peran & Tanggung Jawab Modul (Teknis vs Komunitas)

| Anggota Tim | Jabatan Komunitas | Track Teknis | Modul Fitur & Penugasan Spesifik |
| :--- | :--- | :--- | :--- |
| **Rafli** *(Lead)* | **Ketua (President)** | **Core Architecture, RBAC & Kontrol Event** | • Arsitektur folder, Data Models inti (`user_model.dart`, `motorcycle_model.dart`, `event_registration_model.dart`)<br>• Routing berbasis role (Ketua dan Wakil memakai hak yang sama)<br>• **Kontrol status event:** approve/tolak draft, **Mulai Event**, **Akhiri Event** (memanggil perhitungan podium milik Raihan) di `tab_persetujuan_view.dart`<br>• **Firestore Security Rules** (`firestore.rules`): hak tulis per role dan per field, `role` tidak boleh diubah client, hasil terkunci saat `COMPLETED`<br>• `cloudinary_service.dart` (unsigned upload preset, dipakai Ferdi dan Alfa)<br>• Gatekeeper Git (Review & Merge PR ke `main`)<br>• Monitoring kas dan log diskualifikasi; ikut melakukan scrut ulang lewat layar milik Alfa |
| **Dika** | **Bendahara** | **Finansial, Verifikasi Pembayaran & Nomor Balap** | • **Verifikasi Pembayaran:** periksa bukti transfer di `tab_pembayaran_view.dart`<br>• **Klik "Verifikasi Lunas" menjalankan satu Firestore transaction:** cek `events.status == PUBLISHED`, cek belum `PAID`, cek kuota, `newNumber = registeredCount + 1`, naikkan `registeredCount`, isi `assignedStartNumber`, catat `kas_transactions` MASUK<br>• **Tolak bukti bayar** dengan alasan wajib (`paymentRejectionReason`)<br>• Rekapitulasi kas masuk/keluar komunitas di `tab_kas_view.dart` *(Bendahara TIDAK mengurusi teknis mesin)* |
| **Alfa** | **Sekretaris** | **Event, Kehadiran QR & Scrutineering Meja Paddock** | • Form draft event di `tab_event_view.dart`: judul, lokasi, tanggal, **poster (Cloudinary)**, **kelas (tipe + batas piston + braket)**, biaya, kuota<br>• **Verifikasi kehadiran:** pindai QR (`mobile_scanner`) dan tombol **Tutup Verifikasi Kehadiran** (peserta lunas yang belum hadir menjadi `ABSENT`) di `tab_kehadiran_view.dart` *(usulan petugas, perlu konfirmasi tim)*<br>• **Scrutineering Fisik** di `tab_scrut_view.dart`: input `measuredPistonMm`, hanya untuk peserta lunas dan hadir; tanpa toleransi ukur<br>• **Dialog konfirmasi diskualifikasi:** satu dialog (header peringatan merah, ringkasan nomor, batas, ukuran terukur dan selisih, **alasan wajib**, tombol "Batal / Ukur Ulang" dan "Tetapkan Diskualifikasi")<br>• Riwayat scrut (`scrutineeringHistory`, tidak menimpa data lama) dan layar scrut ulang yang juga dipakai Ketua/Wakil<br>• `widgets/event_card.dart` yang menampilkan **sisa kuota** (`quota - registeredCount`) untuk semua role |
| **Raihan** | **Wakil Ketua / Ofisial** | **Telemetri, Braket & Podium** | • Form telemetri di `tab_telemetri_view.dart`: Lane 01/02, Reaction Time, Elapsed Time, total dihitung otomatis, **ringkasan konfirmasi sebelum simpan**<br>• Filter peserta: hanya yang **LUNAS + HADIR + LOLOS SCRUTINEERING**<br>• `BREAKOUT` otomatis bila `totalTime < bracketSeconds` (tidak bisa diubah ke sah); tombol `JUMP_START` dan `DNF`<br>• Satu balap per peserta (`resultId = registrationId`); hasil boleh ditimpa saat `ONGOING`, terkunci saat `COMPLETED`<br>• **Podium juara 1-3** (`podium_service.dart`, `podium_screen.dart`): hanya tampil setelah `COMPLETED`; urut `totalTime`, seri dimenangkan reaction time terkecil; `BREAKOUT`, `JUMP_START`, `DNF` tidak ikut peringkat; disimpan sebagai snapshot `events.podium`<br>• Sebagai Wakil: approve event, mulai/akhiri event, dan scrut ulang memakai layar milik Rafli dan Alfa |
| **Ferdi** | **Anggota (Pembalap)** | **Rider Experience & Profil Motor** | • **Form Profil Motor:** Merk (Honda/Yamaha/Suzuki/**Kawasaki**/Vespa), Nama Kendaraan, Tipe (Matic/Kopling), Diameter Piston (59/60/62/63/66 mm); satu anggota boleh punya beberapa motor<br>• **Daftar event:** pilihan motor difilter (tipe sama dan piston ≤ batas event), tombol "Daftar" nonaktif saat sisa kuota 0, satu pendaftaran per rider per event<br>• Upload bukti bayar (Cloudinary), tampilan alasan bila ditolak, dan **unggah ulang bukti**<br>• **Kartu balap:** nomor balap `#001` dst dan **QR kehadiran** (`qr_flutter`) setelah lunas; status kehadiran (termasuk "dicoret"); badge hijau *Lolos Scrut*; kartu merah *Diskualifikasi* beserta ukuran aktual dan alasan<br>• Tampilan podium (memakai `podium_screen.dart` milik Raihan) |

> **Catatan hak Ketua dan Wakil (PRD bagian 5):** keduanya boleh approve/tolak event, mulai/akhiri event, scrut ulang, dan koreksi hasil waktu selama `ONGOING`. Scrut ulang dilakukan oleh orang yang berbeda dari pengukur pertama.

---

## 2. Pemetaan Kepemilikan File (File Ownership Matrix)

Untuk mencegah *merge conflict*, setiap developer fokus pada file-nya masing-masing. Perubahan skema field pada model atau ERD harus lewat PR ke Rafli terlebih dahulu.

```
lib/
├── models/
│   ├── user_model.dart               <-- Rafli
│   ├── motorcycle_model.dart         <-- Rafli (Ferdi memakai; perubahan skema lewat PR)
│   ├── event_registration_model.dart <-- Rafli (dipakai Dika, Alfa, Ferdi, Raihan: ubah via PR ke Rafli)
│   ├── event_model.dart              <-- Alfa (termasuk quota, registeredCount, bracketSeconds, attendanceClosedAt, podium)
│   ├── kas_model.dart                <-- Dika
│   └── race_result_model.dart        <-- Raihan
├── services/
│   ├── auth_service.dart             <-- Rafli
│   ├── cloudinary_service.dart       <-- Rafli (upload bukti bayar & poster)
│   ├── event_status_service.dart     <-- Rafli (approve/tolak, mulai, akhiri event)
│   ├── event_service.dart            <-- Alfa (draft event, kecocokan kelas, sisa kuota)
│   ├── attendance_service.dart       <-- Alfa (scan QR, tutup verifikasi kehadiran)
│   ├── scrut_service.dart            <-- Alfa (ukur, lolos/DQ, riwayat, scrut ulang)
│   ├── kas_service.dart              <-- Dika (transaksi verifikasi lunas, tolak bukti, kas)
│   ├── motorcycle_service.dart       <-- Ferdi
│   ├── registration_service.dart     <-- Ferdi (daftar event, filter motor cocok, unggah ulang bukti)
│   ├── telemetry_service.dart        <-- Raihan (hasil waktu, BREAKOUT, filter peserta)
│   └── podium_service.dart           <-- Raihan (hitung podium saat akhiri event)
├── screens/
│   ├── login_screen.dart             <-- Rafli
│   ├── register_screen.dart          <-- Ferdi (registrasi akun)
│   ├── home_screen.dart              <-- Ferdi (profil motor, daftar event, kartu balap, badge status)
│   ├── podium_screen.dart            <-- Raihan (menggantikan leaderboard_screen.dart)
│   └── panitia/
│       ├── tab_persetujuan_view.dart <-- Rafli (approve/tolak, mulai/akhiri event)
│       ├── tab_event_view.dart       <-- Alfa (form draft event)
│       ├── tab_kehadiran_view.dart   <-- Alfa (scan QR, tutup verifikasi kehadiran)
│       ├── tab_scrut_view.dart       <-- Alfa (scrutineering, dialog DQ, scrut ulang)
│   ├── tab_pembayaran_view.dart      <-- Dika (verifikasi/tolak bayar -> nomor balap)
│   ├── tab_kas_view.dart              <-- Dika (rekap kas)
│       └── tab_telemetri_view.dart   <-- Raihan (input waktu balap)
├── widgets/
│   ├── event_card.dart               <-- Alfa (sisa kuota, dipakai semua role)
│   ├── qr_kehadiran_card.dart        <-- Ferdi (QR rider)
│   └── ...                           <-- Komponen bersama lain: koordinasi lewat PR
└── firestore.rules (root proyek)     <-- Rafli
```

**Titik koordinasi lintas pemilik:**
* Transaksi verifikasi lunas (Dika) menulis ke `events` (model Alfa) dan `event_registrations` (model Rafli). Sepakati nama field sesuai ERD sebelum coding.
* `tab_telemetri_view.dart` (Raihan) membaca status kehadiran (Alfa) dan scrut (Alfa), jadi field `attendanceStatus` dan `scrutineeringStatus` harus stabil lebih dulu.
* Tombol "Akhiri Event" (Rafli) memanggil `podium_service.dart` (Raihan).
* Pemilihan motor cocok (Ferdi) memakai `vehicleType` dan `maxPistonDiameterMm` dari `event_model.dart` (Alfa).
* Setiap file hanya punya satu pemilik. Konsumen model/service meminta perubahan melalui PR pemiliknya; jangan mengerjakan file yang sama di dua branch.

**Urutan merge yang disarankan:** (1) fondasi model, kontrak, role, dan `firestore.rules` (Rafli), (2) model event dan form event (Alfa) serta model/layanan motor (Ferdi), (3) profil dan pendaftaran rider (Ferdi), lalu verifikasi pembayaran/kuota/nomor/kas (Dika), (4) kehadiran dan scrut (Alfa), (5) telemetri dan podium (Raihan), (6) integrasi kontrol status event (Rafli). Fitur yang tidak memakai kontrak yang belum di-merge jangan dimulai lebih awal.

---

## 3. Protokol Git & Pull Request (Aturan 5 Developer)

### 3.1 Tiga Aturan Emas
1. **Dilarang Push Langsung ke `main`:** Semua perubahan masuk melalui Pull Request (PR).
2. **Satu Fitur = Satu Branch:** 
   * `feat/nama-fitur-nama` (contoh: `feat/motor-form-ferdi`, `feat/scrut-dialog-alfa`, `feat/verifikasi-bayar-dika`, `feat/podium-raihan`, `feat/mulai-akhiri-event-rafli`)
   * `fix/nama-bug-nama`
   * `refactor/nama-modul-nama`
3. **Peer Review Wajib:** 
   * **Dika (Bendahara)** saling review dengan **Ferdi (Pembalap)** *(verifikasi transfer, nomor balap, kuota, dan alur daftar event saling bergantung)*.
   * **Alfa (Sekretaris)** saling review dengan **Raihan (Ofisial)** *(kehadiran dan scrutineering menjadi syarat telemetri, dan podium bergantung pada hasil telemetri)*.
   * **Rafli (Lead)** melakukan *Final Check & Merge*. PR milik Rafli direview oleh Dika atau Raihan secara bergantian.

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
   git commit -m "feat(scrut): implementasi dialog konfirmasi diskualifikasi overspec piston"
   ```
4. **Push ke GitHub & Buka Pull Request:**
   ```bash
   git push -u origin feat/tugas-saya-nama
   ```
5. **Review & Merge:** Setelah di-approve oleh reviewer dan Rafli, merge ke `main`.
