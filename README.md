# draghub

A new Flutter project.

## Pembayaran Midtrans

Pendaftaran lomba drag mendukung pembayaran online sungguhan lewat Midtrans Snap
(mode Sandbox). Karena Snap membutuhkan Server Key, ada backend kecil di folder
[`midtrans-backend`](midtrans-backend).

Panduan lengkap (ambil key, jalankan backend, deploy Vercel, deploy Firestore
rules, dan cara mengetes pembayaran) ada di
[docs/MIDTRANS_SETUP.md](docs/MIDTRANS_SETUP.md).

Quick start:

```powershell
cd midtrans-backend
Copy-Item .env.example .env   # lalu isi MIDTRANS_SERVER_KEY
npm start
```

```powershell
flutter run                   # Android emulator -> http://10.0.2.2:3000
flutter run -d chrome         # Web -> http://localhost:3000
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
