# Menjalankan ngrok untuk Backend Midtrans DragHub

ngrok dipakai kalau backend Midtrans jalan di laptop, tetapi perlu diakses dari
**HP fisik**, **Midtrans**, atau orang lain. Untuk Android emulator / Chrome,
ngrok tidak perlu.

> Kode aplikasi **tidak memakai ngrok secara langsung**. Aplikasi hanya memanggil
> URL backend yang kamu tentukan lewat `MIDTRANS_BACKEND_URL`.

---

## 1. Install ngrok (Windows)

Pilih salah satu:

**A. Lewat winget (paling gampang)**

```powershell
winget install ngrok.ngrok
```

**B. Download manual**

1. Buka https://ngrok.com/download
2. Download versi Windows (zip)
3. Extract `ngrok.exe` ke folder yang ada di PATH, misalnya `C:\ngrok`
4. Tambahkan `C:\ngrok` ke **Environment Variables → Path** (atau jalankan
   `ngrok.exe` langsung dari foldernya)

Cek:

```powershell
ngrok version
```

---

## 2. Daftar & ambil authtoken

1. Daftar gratis di https://dashboard.ngrok.com/signup
2. Buka https://dashboard.ngrok.com/get-started/your-authtoken
3. Copy token-nya, lalu:

```powershell
ngrok config add-authtoken TOKEN_KAMU
```

Ini cukup sekali saja.

---

## 3. Jalankan backend dulu

Buka **terminal 1**:

```powershell
cd C:\praktikum_pemrograman_mobile\draghub\midtrans-backend
npm.cmd start
```

Pastikan muncul:

```text
[midtrans-backend] jalan di http://localhost:3000 (SANDBOX)
```

---

## 4. Jalankan ngrok

Buka **terminal 2** (biarkan terminal 1 tetap hidup):

```powershell
ngrok http 3000
```

Akan muncul sesuatu seperti:

```text
Forwarding   https://abcd-1234-56.ngrok-free.app -> http://localhost:3000
```

Copy URL **https**-nya.

> URL gratis berubah setiap kali ngrok di-restart. Kalau akun ngrok kamu punya
> **static domain** gratis, pakai:
>
> ```powershell
> ngrok http --url=nama-kamu.ngrok-free.app 3000
> ```

---

## 5. Arahkan aplikasi ke URL ngrok

Karena `--dart-define` dibaca saat compile, **hentikan** aplikasi Flutter yang
sedang jalan, lalu jalankan ulang:

```powershell
flutter run --dart-define=MIDTRANS_BACKEND_URL=https://abcd-1234-56.ngrok-free.app
```

Kalau backend di `.env` memakai `PUBLIC_BASE_URL`, ganti juga:

```env
PUBLIC_BASE_URL=https://abcd-1234-56.ngrok-free.app
```

lalu restart backend (`Ctrl+C`, `npm.cmd start` lagi).

---

## 6. Tes

Buka URL ngrok di browser:

```text
https://abcd-1234-56.ngrok-free.app
```

Pertama kali akan muncul halaman peringatan ngrok. Klik **Visit Site**. Kalau
muncul JSON:

```json
{"status":"ok","service":"draghub-midtrans-backend", ...}
```

berarti backend sudah bisa diakses publik.

Dari aplikasi, coba daftar event → pilih Midtrans → bayar. Kalau ada error
koneksi, cek:

- Terminal backend masih hidup?
- Terminal ngrok masih hidup?
- URL `--dart-define` sama persis dengan URL ngrok (https, tanpa slash di akhir)?
- HP dan laptop sama-sama punya internet?

---

## 7. Kenapa tetap bisa jalan padahal ngrok gratis suka muncul warning?

Request API dari Flutter sudah otomatis mengirim header
`ngrok-skip-browser-warning: true`, jadi tidak kena halaman peringatan HTML.
Backend juga sudah mengizinkan header itu di CORS.

Kalau nanti menambah request baru ke backend, tambahkan juga header tersebut.

---

## 8. Kapan tidak perlu ngrok?

| Cara menjalankan | Perlu ngrok? |
| --- | --- |
| Android emulator + backend laptop | Tidak (`10.0.2.2:3000`) |
| Chrome + backend laptop | Tidak (`localhost:3000`) |
| HP fisik + backend laptop | Ya |
| Midtrans webhook ke backend laptop | Ya |
| Backend deploy Vercel/Railway/Render | Tidak |

Catatan keamanan: URL ngrok bisa diakses siapa saja yang tahu alamatnya. Untuk
praktikum tidak masalah, tapi matikan ngrok kalau sudah selesai demo.
