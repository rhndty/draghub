# DOKUMEN HANDOVER DATABASE CLOUD FIRESTORE
## Proyek: DragHub Mobile (Komunitas Motor Drag Resmi)
**Tanggal Rilis:** 9 November 2026  
**Target Pengguna:** Developer / Rekan Tim Penanggung Jawab Setup Firebase  
**Basis Data:** Google Cloud Firestore (NoSQL Document Store)  
**Dokumen Terkait:** [PRD_DragHub.md](docs/PRD_DragHub.md) | [ERD_DragHub.md](docs/ERD_DragHub.md) | [Pembagian_Tugas_GitFlow.md](docs/Pembagian_Tugas_GitFlow.md)

---

## 1. Ringkasan & Instruksi Singkat

Halo bro! Dokumen ini adalah **panduan lengkap dan siap pakai** untuk membuat seluruh koleksi, dokumen contoh, dan aturan keamanan database di **Google Firebase Console**.

Aplikasi ini menggunakan model database **NoSQL (Koleksi & Dokumen)** yang saling terhubung menggunakan UID dan Auto-ID. Pastikan penamaan *collection* dan *field* mengikuti huruf besar-kecil (*case-sensitive*) persis seperti yang tertulis di bawah ini.

---

## 2. Struktur Hierarki Koleksi (Collection Hierarchy)

```
Cloud Firestore
├── 📁 users/                   <-- Koleksi Akun Pengguna & Otorisasi Role (RBAC)
├── 📁 motorcycles/             <-- Koleksi Motor Balap Milik Anggota
├── 📁 events/                  <-- Koleksi Kejuaraan & Agenda Balap
│   └── 📁 classes/             <-- Subkoleksi Kelas Balap per Event (Matic 63, Kopling 66)
├── 📁 event_registrations/     <-- Koleksi Pendaftaran, Bukti Bayar, & Status Scrut
├── 📁 race_results/            <-- Koleksi Catatan Waktu Sensor (RT & ET) untuk Leaderboard
└── 📁 kas_transactions/        <-- Koleksi Buku Kas Keluar & Masuk Komunitas
```

---

## 3. Rincian Koleksi, Tipe Data & Dummy Data Siap Input

Silakan buka **Firebase Console** $\rightarrow$ **Firestore Database** $\rightarrow$ **Start Collection** dan masukkan data berikut untuk pengetesan awal:

---

### A. Koleksi: `users`
* **Nama Koleksi:** `users`
* **Fungsi:** Menyimpan profil dan jabatan organisasi. Dokumen ID menggunakan `UID` dari Firebase Authentication.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `uid` | String | UID Firebase Auth pengguna |
| `fullName` | String | Nama lengkap |
| `email` | String | Alamat email terdaftar |
| `phoneNumber` | String | Nomor WhatsApp aktif |
| `role` | String | Nilai wajib salah satu dari: `'ketua'`, `'wakil'`, `'sekretaris'`, `'bendahara'`, `'anggota'` |
| `createdAt` | Timestamp | Waktu pembuatan akun (`FieldValue.serverTimestamp()`) |

#### Contoh Dokumen Dummy Siap Input di Firebase Console:
* **Document ID:** `USER_RAFLI_KETUA`
  ```json
  {
    "uid": "USER_RAFLI_KETUA",
    "fullName": "Rafli Gilang",
    "email": "ketua@draghub.com",
    "phoneNumber": "081234567890",
    "role": "ketua",
    "createdAt": "2026-11-09T08:00:00Z"
  }
  ```
* **Document ID:** `USER_DIKA_BENDAHARA`
  ```json
  {
    "uid": "USER_DIKA_BENDAHARA",
    "fullName": "Dika Bendahara",
    "email": "bendahara@draghub.com",
    "phoneNumber": "081234567891",
    "role": "bendahara",
    "createdAt": "2026-11-09T08:00:00Z"
  }
  ```
* **Document ID:** `USER_FERDI_RIDER`
  ```json
  {
    "uid": "USER_FERDI_RIDER",
    "fullName": "Ferdi Rider",
    "email": "ferdi@gmail.com",
    "phoneNumber": "081234567892",
    "role": "anggota",
    "createdAt": "2026-11-09T08:00:00Z"
  }
  ```

---

### B. Koleksi: `motorcycles`
* **Nama Koleksi:** `motorcycles`
* **Fungsi:** Menyimpan motor pembalap beserta ukuran diameter piston mesin.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `bikeId` | String | Auto-ID Firestore |
| `userId` | String | UID pembalap pemilik motor (Foreign Key ke `users`) |
| `brand` | String | Pilihan merk: `'Honda'`, `'Yamaha'`, `'Suzuki'`, `'Vespa'`, `'Kawasaki'` |
| `modelName` | String | Model motor: misal `'Vario 125'`, `'Aerox 155'`, `'Mx King'`, `'Sprint'` |
| `vehicleType` | String | Jenis transmisi: `'MATIC'` atau `'KOPLING'` |
| `pistonDiameterMm` | Number (Double) | Ukuran diameter piston dalam satuan mm (contoh: `62.0`) |
| `createdAt` | Timestamp | Waktu penambahan motor |

#### Contoh Dokumen Dummy:
* **Document ID:** `BIKE_VARIO_62`
  ```json
  {
    "bikeId": "BIKE_VARIO_62",
    "userId": "USER_FERDI_RIDER",
    "brand": "Honda",
    "modelName": "Vario 125",
    "vehicleType": "MATIC",
    "pistonDiameterMm": 62.0,
    "createdAt": "2026-11-09T09:00:00Z"
  }
  ```

---

### C. Koleksi: `events` & Subkoleksi: `classes`
* **Nama Koleksi:** `events`
* **Fungsi:** Menyimpan agenda event balap resmi atau latber.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `eventId` | String | Auto-ID Firestore |
| `title` | String | Judul event (contoh: *IDW Round 3 National Drag Fest*) |
| `location` | String | Nama sirkuit / lokasi |
| `eventDate` | Timestamp | Tanggal pelaksanaan event |
| `registrationFee` | Number | Biaya pendaftaran per kelas balap (Rupiah) |
| `distanceMeter` | Number | Jarak lintasan: `201` atau `402` meter |
| `status` | String | Status event: `'DRAFT'` (dibuat sekretaris), `'PUBLISHED'` (disetujui ketua), `'STAGE_READY'` (live race), `'COMPLETED'` |
| `createdBy` | String | UID akun Sekretaris (Alfa) |
| `approvedBy` | String | UID akun Ketua (Rafli) |
| `createdAt` | Timestamp | Waktu draft dibuat |

#### Subkoleksi: `events/{eventId}/classes`
* **Fungsi:** Mengatur kelas balap berbasis batas maksimal diameter piston.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `classId` | String | Auto-ID subkoleksi |
| `className` | String | Nama kelas: contoh `'Matic s.d Piston 63mm'` |
| `vehicleType` | String | `'MATIC'` atau `'KOPLING'` |
| `maxPistonDiameterMm` | Number (Double) | **Batas piston maksimal kelas** (contoh: `63.0` atau `66.0`) |

#### Contoh Dokumen Dummy:
* **Document ID Event:** `EVENT_IDW_2026`
  ```json
  {
    "eventId": "EVENT_IDW_2026",
    "title": "IDW Round 3 National Drag Fest",
    "location": "Sirkuit NP Gelora Bung Tomo, Surabaya",
    "eventDate": "2026-12-15T08:00:00Z",
    "registrationFee": 350000,
    "distanceMeter": 201,
    "status": "PUBLISHED",
    "createdBy": "USER_ALFA_SEKRETARIS",
    "approvedBy": "USER_RAFLI_KETUA",
    "createdAt": "2026-11-09T08:30:00Z"
  }
  ```
* **Sub-Document Class:** `events/EVENT_IDW_2026/classes/CLASS_MATIC_63`
  ```json
  {
    "classId": "CLASS_MATIC_63",
    "className": "Matic s.d Piston 63mm",
    "vehicleType": "MATIC",
    "maxPistonDiameterMm": 63.0
  }
  ```

---

### D. Koleksi: `event_registrations`
* **Nama Koleksi:** `event_registrations`
* **Fungsi:** Menyimpan pendaftaran pembalap, verifikasi struk transfer oleh Bendahara, dan hasil inspeksi fisik piston oleh Sekretaris.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `registrationId` | String | Auto-ID Firestore |
| `eventId` | String | ID event yang diikuti |
| `classId` | String | ID kelas balap yang dipilih |
| `userId` | String | UID pembalap pendaftar |
| `bikeId` | String | ID motor yang dipakai balap |
| `riderName` | String | Nama pembalap |
| `bikeName` | String | Merk & model motor (contoh: *Honda Vario 125*) |
| `vehicleType` | String | `'MATIC'` atau `'KOPLING'` |
| `pistonDiameterMm` | Number | Ukuran piston yang didaftarkan (contoh: `62.0`) |
| `paymentProofUrl` | String | URL Cloud Storage foto struk bukti bayar |
| `paymentStatus` | String | `'PENDING'` $\rightarrow$ diverifikasi Bendahara $\rightarrow$ `'PAID'` |
| `verifiedBy` | String / Null | UID akun Bendahara (Dika) |
| `assignedStartNumber` | String / Null | **Nomor Balap Resmi** (contoh: `'#089'`). **Hanya muncul jika `paymentStatus == 'PAID'`**. Null jika pending. |
| `measuredPistonMm` | Number / Null | Hasil ukur fisik aktual jangka sorong saat scrutineering di paddock |
| `scrutineeringStatus` | String | `'PENDING'` $\rightarrow$ dicek Sekretaris $\rightarrow$ `'PASSED'` (Lolos) atau `'DISQUALIFIED'` (Piston kegedean) |
| `disqualificationReason` | String / Null | Berita acara alasan resmi jika didiskualifikasi (contoh: *"Piston 64.5mm over 1.5mm dari batas 63mm"*) |
| `scrutineeredBy` | String / Null | UID akun Sekretaris / Ofisial (Alfa / Raihan) |
| `registeredAt` | Timestamp | Waktu pendaftaran |
| `verifiedAt` | Timestamp / Null | Waktu diverifikasi lunas |

#### Contoh Dokumen Dummy:
* **Document ID:** `REG_2026_089`
  ```json
  {
    "registrationId": "REG_2026_089",
    "eventId": "EVENT_IDW_2026",
    "classId": "CLASS_MATIC_63",
    "userId": "USER_FERDI_RIDER",
    "riderName": "Ferdi Rider",
    "bikeName": "Honda Vario 125",
    "vehicleType": "MATIC",
    "pistonDiameterMm": 62.0,
    "paymentProofUrl": "https://placehold.co/600x400/png?text=Bukti+Transfer+Lunas",
    "paymentStatus": "PAID",
    "verifiedBy": "USER_DIKA_BENDAHARA",
    "assignedStartNumber": "#089",
    "measuredPistonMm": 62.0,
    "scrutineeringStatus": "PASSED",
    "disqualificationReason": null,
    "scrutineeredBy": "USER_ALFA_SEKRETARIS",
    "registeredAt": "2026-11-09T09:15:00Z",
    "verifiedAt": "2026-11-09T09:30:00Z"
  }
  ```

---

### E. Koleksi: `race_results` (Telemetri Sensor & Leaderboard)
* **Nama Koleksi:** `race_results`
* **Fungsi:** Menyimpan catatan waktu sensor lampu finish balap drag 201m/402m.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `resultId` | String | Auto-ID Firestore |
| `eventId` | String | ID kejuaraan |
| `registrationId` | String | ID dokumen pendaftaran terkait |
| `startNumber` | String | Nomor balap (diambil dari `assignedStartNumber`, misal: `'#089'`) |
| `lane` | String | Jalur lintasan: `'LANE 01'` atau `'LANE 02'` |
| `stage` | String | Babak: `'QUALIFYING'` atau `'FINAL'` |
| `reactionTime` | Number (Double) | Waktu reaksi lampu hijau start (detik) |
| `elapsedTime` | Number (Double) | **Waktu tempuh sensor garis finish (detik)** |
| `totalTime` | Number (Double) | Hasil perhitungan: `reactionTime + elapsedTime` |
| `status` | String | `'VALID'`, `'JUMP_START'`, `'DNF'`, `'DISQUALIFIED'` |
| `recordedBy` | String | UID ofisial pencatat waktu (Raihan/Wakil) |
| `recordedAt` | Timestamp | Waktu pencatatan sensor balap |

#### Contoh Dokumen Dummy:
* **Document ID:** `RESULT_089_HEAT1`
  ```json
  {
    "resultId": "RESULT_089_HEAT1",
    "eventId": "EVENT_IDW_2026",
    "registrationId": "REG_2026_089",
    "startNumber": "#089",
    "lane": "LANE 01",
    "stage": "FINAL",
    "reactionTime": 0.038,
    "elapsedTime": 7.189,
    "totalTime": 7.227,
    "status": "VALID",
    "recordedBy": "USER_RAIHAN_OFISIAL",
    "recordedAt": "2026-12-15T14:30:00Z"
  }
  ```

---

### F. Koleksi: `kas_transactions` (Buku Kas Komunitas)
* **Nama Koleksi:** `kas_transactions`
* **Fungsi:** Pencatatan arus kas uang masuk dan keluar oleh Bendahara.

| Nama Field | Tipe Data | Deskripsi / Nilai yang Diizinkan |
| :--- | :--- | :--- |
| `transactionId` | String | Auto-ID Firestore |
| `title` | String | Judul mutasi kas (contoh: *Pendaftaran Event IDW #089*) |
| `category` | String | Kategori: `'PENDAFTARAN_EVENT'`, `'IURAN_ANGGOTA'`, `'SEWA_SIRKUIT'`, `'OPERASIONAL'` |
| `type` | String | `'MASUK'` atau `'KELUAR'` |
| `amount` | Number | Nominal uang dalam Rupiah (contoh: `350000`) |
| `recordedBy` | String | UID Bendahara pencatat (Dika) |
| `transactionDate` | Timestamp | Tanggal mutasi kas |

#### Contoh Dokumen Dummy:
* **Document ID:** `TX_2026_001`
  ```json
  {
    "transactionId": "TX_2026_001",
    "title": "Pendaftaran IDW Round 3 - Ferdi #089",
    "category": "PENDAFTARAN_EVENT",
    "type": "MASUK",
    "amount": 350000,
    "recordedBy": "USER_DIKA_BENDAHARA",
    "transactionDate": "2026-11-09T09:30:00Z"
  }
  ```

---

## 4. Indeks Kueri Firestore (Compound Indexes)

Agar aplikasi Flutter tidak mengalami *crash* saat melakukan filter dan pengurutan data di Firebase, buat 3 indeks komposit ini di menu **Firestore Database** $\rightarrow$ **Indexes** $\rightarrow$ **Add Index**:

1. **Leaderboard Tercepat:**
   * Collection: `race_results`
   * Fields: `eventId` (Ascending) + `status` (Ascending) + `elapsedTime` (Ascending)
2. **Riwayat Buku Kas Terbaru:**
   * Collection: `kas_transactions`
   * Fields: `type` (Ascending) + `transactionDate` (Descending)
3. **Antrean Verifikasi Pendaftaran:**
   * Collection: `event_registrations`
   * Fields: `eventId` (Ascending) + `paymentStatus` (Ascending) + `registeredAt` (Ascending)

---

## 5. Aturan Keamanan Siap Pakai (Firestore Security Rules)

Buka menu **Firestore Database** $\rightarrow$ tab **Rules**, lalu copy-paste seluruh kode keamanan ini:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    // Koleksi Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (request.auth.uid == userId || getUserRole() == 'ketua');
    }

    // Koleksi Motor Pembalap
    match /motorcycles/{bikeId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated();
    }

    // Koleksi Event & Subkoleksi Kelas
    match /events/{eventId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && getUserRole() in ['sekretaris', 'ketua'];
      allow update: if isAuthenticated() && getUserRole() in ['ketua', 'wakil', 'sekretaris'];
      
      match /classes/{classId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && getUserRole() in ['sekretaris', 'ketua'];
      }
    }

    // Koleksi Pendaftaran Event
    match /event_registrations/{regId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && getUserRole() in ['bendahara', 'sekretaris', 'ketua', 'wakil'];
    }

    // Koleksi Telemetri & Leaderboard
    match /race_results/{resId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated() && getUserRole() in ['wakil', 'sekretaris', 'ketua'];
    }

    // Koleksi Kas Komunitas
    match /kas_transactions/{transId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated() && getUserRole() == 'bendahara';
    }
  }
}
```

---

## 6. Checklist Pembuatan Database

Silakan gunakan checklist ini saat membuat database di Firebase Console:
- [ ] Buat koleksi `users` dan masukkan 1 akun role `ketua` dan 1 akun role `bendahara`.
- [ ] Buat koleksi `motorcycles` dengan field diameter piston.
- [ ] Buat koleksi `events` dan tambahkan subkoleksi `classes` (`maxPistonDiameterMm`).
- [ ] Buat koleksi `event_registrations` untuk pengujian verifikasi bayar & scrutineering.
- [ ] Buat koleksi `race_results` untuk pengetesan leaderboard sensor finish.
- [ ] Buat koleksi `kas_transactions` untuk pencatatan mutasi kas komunitas.
- [ ] Pasang kode di atas ke tab **Rules** Firebase Console dan klik **Publish**.
- [ ] Tambahkan 3 Compound Indexes di tab **Indexes**.

