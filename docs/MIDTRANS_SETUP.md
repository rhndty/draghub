# Setup Midtrans DragHub (Sandbox) — Pembayaran Pendaftaran Lomba Drag

Dokumen ini menjelaskan cara membuat pembayaran Midtrans **benar-benar berjalan**
di aplikasi Flutter DragHub, khususnya saat rider mendaftar lomba balapan drag.

---

## 1. Kenapa butuh backend?

Midtrans **Snap** tidak bisa dibuat langsung dari Flutter, karena pembuatan
transaksi wajib memakai **Server Key**. Kalau Server Key ditaruh di aplikasi,
siapa pun bisa membongkar APK dan mencurinya.

Karena itu alurnya:

```
Flutter (rider)                 Backend kecil                Midtrans
     |                               |                         |
     |-- POST /create-transaction -->|                         |
     |   {orderId, grossAmount}      |-- Server Key (Basic) -->|
     |                               |<-- token + redirect_url-|
     |<-- token + redirect_url ------|                         |
     |                                                         |
     |-- buka redirect_url (WebView/browser) ----------------->|
     |                                                         |
     |<-- redirect ke /api/finish setelah bayar --------------|
     |                                                         |
     |-- GET /api/status/:orderId -->|-- cek status asli ----->|
     |<-- transaction_status --------|<------------------------|
     |
     |-- kalau settlement/capture: update Firestore (PAID,
         nomor balap, buku kas)
```

Backend sudah disiapkan di folder [`midtrans-backend`](../midtrans-backend).

---

## 2. Ambil Server Key Midtrans (kalau lupa di mana)

1. Buka **https://dashboard.sandbox.midtrans.com** (bukan dashboard production).
2. Login dengan akun Midtrans kamu.
3. Klik ikon **Settings / Pengaturan** di kiri bawah.
4. Buka **Access Keys**.
5. Di sana ada:
   - **Server Key** → dipakai backend (`MIDTRANS_SERVER_KEY`)
   - **Client Key** → dipakai kalau nanti mau pakai Snap.js di web
     (`MIDTRANS_CLIENT_KEY`)
6. Pastikan **Snap** aktif: **Settings → Snap Preferences → Snap enabled**.

> Kalau akunnya belum ada: daftar di https://midtrans.com, pilih mode Sandbox.
> Jangan pakai production key untuk praktikum — itu uang asli.

---

## 3. Jalankan backend secara lokal

Prasyarat: **Node.js 20.6+** (sudah dicek: Node v24 tersedia).

```powershell
cd midtrans-backend

# 1. Salin konfigurasi
Copy-Item .env.example .env

# 2. Edit .env, isi MIDTRANS_SERVER_KEY dan MIDTRANS_CLIENT_KEY
notepad .env
```

Isi `.env` minimal:

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxxxxxxxxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxxxxxxxxxx
MIDTRANS_IS_PRODUCTION=false
PUBLIC_BASE_URL=http://localhost:3000
PORT=3000
```

Jalankan:

```powershell
npm start
```

Kalau muncul error PowerShell `npm.ps1 cannot be loaded because running scripts
is disabled`, pakai salah satu ini:

```powershell
npm.cmd start
# atau langsung tanpa npm:
node --env-file=.env server.js
```

Cek di browser: **http://localhost:3000** → harus muncul JSON
`{"status":"ok", ...}`.

### Menjalankan Flutter

Android emulator otomatis memakai `http://10.0.2.2:3000`:

```powershell
flutter run
```

Web / desktop / iOS simulator memakai `http://localhost:3000`:

```powershell
flutter run -d chrome
```

Kalau backend ada di alamat lain (mis. HP fisik / ngrok):

```powershell
flutter run --dart-define=MIDTRANS_BACKEND_URL=https://xxxx-xxx.ngrok-free.app
```

Cara install dan menjalankan ngrok langkah demi langkah ada di
[`docs/NGROK.md`](NGROK.md).

> **Penting:** kalau pakai ngrok, backend hanya hidup selama laptop dan ngrok
> menyala. Untuk demo di kelas itu cukup. Kalau ingin selalu online, deploy ke
> Vercel (langkah 4).

---

## 4. Deploy backend ke Vercel (agar tidak bergantung ngrok)

Backend sudah disiapkan agar langsung bisa jadi Vercel Serverless Functions
(folder `api/`).

```powershell
cd midtrans-backend
npx vercel
npx vercel --prod
```

Lalu di dashboard Vercel → **Project → Settings → Environment Variables**, isi:

| Name                     | Value                              |
| ------------------------ | ---------------------------------- |
| `MIDTRANS_SERVER_KEY`    | `SB-Mid-server-...`                |
| `MIDTRANS_CLIENT_KEY`    | `SB-Mid-client-...`                |
| `MIDTRANS_IS_PRODUCTION` | `false`                            |
| `PUBLIC_BASE_URL`        | `https://nama-project.vercel.app`  |

Redeploy setelah menambah env. Tes:

- `https://nama-project.vercel.app/` → JSON status ok
- `https://nama-project.vercel.app/api/finish` → halaman "Pembayaran Selesai"

Jalankan Flutter dengan URL Vercel:

```powershell
flutter run --dart-define=MIDTRANS_BACKEND_URL=https://nama-project.vercel.app
```

Setelah backend online, di dashboard Midtrans set
**Settings → Configuration → Payment Notification URL** ke:

```
https://nama-project.vercel.app/api/notification
```

> Webhook ini memverifikasi signature Midtrans. Untuk praktikum, status
> pembayaran tetap diverifikasi dari aplikasi lewat `/api/status`. Kalau nanti
> mau produksi, update Firestore langsung dari webhook memakai `firebase-admin`
> agar pembayaran tetap tercatat walau aplikasi ditutup.

---

## 5. Deploy Firestore Rules (WAJIB)

Ada bug lama di rules yang membuat pencatatan kas Midtrans gagal
(`permission-denied`):

```diff
- allow create: if ... request.resource.data.type == 'IN';
+ allow create: if ... request.resource.data.type == 'MASUK' ...;
```

Aplikasi menulis `type: 'MASUK'`, bukan `'IN'`. Rules sudah diperbaiki di
[`firestore.rules`](../firestore.rules), dan `firebase.json` sudah diarahkan ke
file rules tersebut. Deploy dengan:

```powershell
firebase deploy --only firestore:rules --project draghub-c0ecb
```

Kalau belum punya Firebase CLI:

```powershell
npm.cmd install -g firebase-tools
firebase login
firebase deploy --only firestore:rules --project draghub-c0ecb
```

Tanpa langkah ini, pembayaran bisa sukses di Midtrans tetapi saat menulis buku
kas akan muncul error `PERMISSION_DENIED`.

---

## 6. Cara mengetes pembayaran di Sandbox

1. Login sebagai rider.
2. Buka tab **UPCOMING** → pilih event → **DAFTAR SEKARANG**.
3. Pilih motor & nama, biarkan metode **Midtrans (Online)**.
4. Tekan **BAYAR & DAFTAR (MIDTRANS)**.
5. Di halaman Snap pilih metode, misalnya **BCA Virtual Account** atau **QRIS**.
6. Karena ini sandbox, pembayaran disimulasikan dari dashboard:
   - Buka **https://dashboard.sandbox.midtrans.com/simulator**
   - Pilih transaksi dengan Order ID yang tampil di aplikasi
   - Ubah status menjadi **Settlement**
7. Kembali ke aplikasi, tekan **SAYA SUDAH BAYAR / CEK STATUS**.
8. Kalau sudah `settlement`, aplikasi akan:
   - mengubah `paymentStatus` pendaftaran menjadi `PAID`
   - menerbitkan nomor balap `#001` dst
   - menambah `registeredCount` event
   - mencatat transaksi ke `kas_transactions`

Tips metode yang paling cepat untuk demo:

- **Kartu kredit sandbox**: `4811 1111 1111 1114`, expiry bebas (masa depan),
  CVV `123`, OTP `112233`.
- **QRIS / GoPay**: simulasi lewat halaman simulator di atas.

---

## 7. Kalau rider menutup halaman pembayaran

Pendaftaran tetap tersimpan dengan `paymentStatus = PENDING` dan
`paymentProofUrl = 'MIDTRANS_PENDING'`. Rider bisa membayar lagi dari tab
**ONGOING** → kartu tiket → tombol **BAYAR VIA MIDTRANS**. Nomor balap baru
terbit setelah status Midtrans benar-benar lunas.

---

## 8. Troubleshooting

| Gejala | Penyebab & solusi |
| --- | --- |
| `Gagal membuat transaksi: Connection refused` | Backend belum jalan. Jalankan `npm start` di `midtrans-backend`. Di emulator pakai `10.0.2.2`, bukan `localhost`. |
| `MIDTRANS_SERVER_KEY belum di-set` | File `.env` belum dibuat / env Vercel belum diisi. |
| `CLEARTEXT communication not permitted` | Sudah ditangani oleh `network_security_config.xml` untuk `10.0.2.2`/`localhost`. Pastikan file itu ikut ter-build. |
| `PERMISSION_DENIED` saat menulis kas | Rules lama masih terpasang. Jalankan `firebase deploy --only firestore:rules`. |
| Status selalu `pending` | Pembayaran sandbox belum disimulasikan. Buka dashboard **Simulator**, set **Settlement**. |
| `order_id has been paid` / `order_id already taken` | Order ID sudah dipakai. Aplikasi membuat Order ID baru setiap kali tombol bayar ditekan; kalau error, tutup sheet lalu coba lagi. |
| `transaction doesn't exist` | Key production dipakai untuk transaksi sandbox (atau sebaliknya). Pastikan `MIDTRANS_IS_PRODUCTION=false` dan key berawalan `SB-Mid-`. |
| Webhook tidak masuk | `PUBLIC_BASE_URL` harus HTTPS publik. `localhost` tidak bisa dihubungi Midtrans. |
| Popup pembayaran tidak terbuka di Chrome | Browser memblokir popup. Klik lagi tombol **BUKA PEMBAYARAN** (harus dari klik langsung). |

---

## 9. Catatan keamanan (penting untuk laporan/presentasi)

- **Server Key tidak pernah masuk ke Flutter.** Hanya ada di `.env` backend.
- `.env` sudah masuk `.gitignore`. Jangan commit.
- Untuk praktikum, finalisasi Firestore dilakukan dari aplikasi setelah status
  Midtrans dicek. Untuk production, pindahkan finalisasi ke webhook
  `/api/notification` memakai **firebase-admin**, lalu kunci rules sehingga
  rider tidak bisa menulis `PAID` sendiri.
- Jangan set `MIDTRANS_IS_PRODUCTION=true` kecuali benar-benar siap menerima
  uang asli.

---

## 10. File yang terlibat

| File | Fungsi |
| --- | --- |
| `midtrans-backend/server.js` | Server lokal (Node.js, tanpa dependency) |
| `midtrans-backend/api/*.js` | Endpoint untuk Vercel |
| `midtrans-backend/lib/midtrans.js` | Panggilan Snap, cek status, verifikasi signature |
| `lib/services/midtrans_service.dart` | Client HTTP Flutter ke backend |
| `lib/widgets/midtrans_snap_page.dart` | WebView halaman pembayaran Snap |
| `lib/widgets/midtrans_payment_sheet.dart` | UI pembayaran + cek status |
| `lib/screens/rider/register_event_modal.dart` | Pilihan Midtrans / transfer manual saat daftar |
| `lib/screens/rider/rider_ongoing_view.dart` | Tombol bayar ulang kalau pembayaran belum selesai |
| `lib/services/kas_service.dart` | Menulis PAID + nomor balap + buku kas |
| `firestore.rules` | Perbaikan izin pencatatan kas (`MASUK`) |
